# Проблема N+1 запросов

## База данных

Проблема N+1 запросов - это неэффективный способ обращения к базе данных, при котором на каждую строку таблицы, полученную из базы данных, совершаются дополнительные SQL-запросы.

Рассмотрим API-запрос, который отдаёт список товаров, а для каждого товара - его категорию. Пример JSON-а:

```json
{
  "products": [
    {
      "id": 1,
      "name": "Футболка",
      "category": {
        "id": 1,
        "name": "Одежда"
      }
    },
    {
      "id": 2,
      "name": "Шкаф",
      "category": {
        "id": 2,
        "name": "Мебель"
      }
    }
  ]
}
```

Вот самый простой способ получить такие данные из базы данных:

1. Выполнить SQL-запрос для получения товаров:

    ```sql
    SELECT * FROM products;
    ```

2. Для каждого полученного товара выполнить SQL-запрос его категории по идентификатору категории:

    ```sql
    SELECT * FROM categories WHERE categories.id = ?;
    ```

При всей простоте, главный недостаток такого решения в том, что количество SQL-запросов бесконечно увеличивается при увеличении количества строк, полученных на первом шаге.

Например, при уровне вложенности 5 и количестве элементов 100 придётся выполнить 5 * (100) + 1 = 501 SQL-запрос! И это только при связях один-к-одному.

Гораздо более оптимальным решением будет следующий алгоритм:

1. Выполнить SQL-запрос для получения товаров:

    ```sql
    SELECT * FROM products;
    ```

2. Собрать идентификаторы всех категорий из полученных товаров.

3. Выполнить единственный SQL-запрос в таблицу категорий с фильтрацией по всем полученным идентификаторам через `IN`:

    ```sql
    SELECT * FROM categories WHERE categories.id IN (?);
    ```

4. Построить хеш-таблицу из полученных категорий, где ключ - это идентификатор категории, а значение - категория.

5. Единственным проходом по товарам проставить им категории, обращаясь к хеш-таблице по идентификатору категории.

Данный алгоритм можно распространить на все уровни вложенности, из-за чего количество запросов, необходимых для получения сложной структуры объектов, будет зависеть только от количества вложенностей, что является константой в условиях неизменяющейся структуры данных. А учитывая, что сложность вставки и поиска в хеш-таблице в среднем занимает константное время, то и количество строк, получаемых из базы данных, не будет оказывать существенное влияние на сложность алгоритма.

## Клиент-серверное взаимодействие

Когда кто-либо упоминает проблему N+1 запросов, он скорее всего имеет ввиду SQL-запросы, но данная проблема может возникнуть и на уровне клиент-серверного взаимодействия, так же вызывая проблемы производительности.

Предположим, что в каталоге интернет-магазина, где отображается список товаров, появилась задача отображать индикатор нахождения товара в избранном пользователя. Ранее этот индикатор можно было получить только выполнив дополнительный API-запрос на получение полной информации о товаре.

Если решать задачу без доработки API, то клиент должен будет совершить дополнительный API-запрос на сервер для каждого товара, который отображается на экране.

Оптимальным решением будет доработать API, чтобы нужный индикатор выдавался в API-запросе списка товаров, чтобы клиенту не было необходимости самостоятельно совершать N дополнительных API-запросов.
