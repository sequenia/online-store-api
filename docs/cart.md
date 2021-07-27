# Корзина

## Введение

Корзина - это текущий заказ пользователя, в который он набирает товары для покупки.

Клиент покупает конкретные варианты товаров с указанием количеств, что определяет минимальную структуру для хранения информации о товарах в корзине.

## Структура данных

Корзину можно рассматривать как частный случай заказа, который находится в определенном статусе и содержит одну или более позиций. В таком случае, не придётся создавать дополнительные таблицы для хранения корзины и информации о товарах в ней.

Если администратор магазина поменяет цены на варианты, то они не должны измениться в существующих заказах. Значит, необходимо дублировать актуальную цену варианта в позицию заказа в момент добавления варианта в корзину.

В связи с вышеперечисленным можно создать следующую структуру таблиц.

Заказы:

```sql
CREATE TABLE orders (
  id bigserial PRIMARY KEY, -- Идентификатор заказа
  status integer -- Статус заказа
)
```

Позиции заказа:

```sql
CREATE TABLE order_items (
  id bigserial PRIMARY KEY, -- Идентификатор позиции заказа
  order_id bigint, -- Идентификатор заказа, которому принадлежит позиция
  variant_id bigint, -- Идентификатор варианта в позиции заказа
  count integer, -- Количество вариантов товара,
  price number(8, 2) -- Цена варианта на момент добавления его в корзину
)
```

Структура данных для сериализации в JSON:

```java
public class Order {
  private Long id;
  private OrderStatus status;
  private List<OrderItem> items;
}

public enum OrderStatus {
  CART(0, "cart");

  private final int value;
  private final String name;

  OrderStatus(int value, String name) {
    this.value = value;
    this.name = name;
  }
}

public class OrderItem {
  private Long id;
  private Variant variant;
  private Integer count;
  private OrderItemPrice price;
}

public class OrderItemPrice {
  private BigDecimal amount;
}

public class Variant {
  private Long id;
  private String name;
  private Product product;
  private List<OptionValue> optionValues;
}

public class Product {
  private Long id;
  private String name;
}

public class OptionValue {
  private Long id;
  private String name;
  private String presentation;
  private Option option;
}

public class Option {
  private Long id;
  private String name;
  private String presentation;
}
```

Пример выдачи корзины в API:

```json
{
  "cart": {
    "id": 1,
    "status": "cart",
    "items": [
      {
        "id": 1,
        "count": 2,
        "price": {
          "amount": "900.00"
        },
        "variant": {
          "id": 1,
          "name": "Футболка Красная S",
          "product": {
            "id": 1,
            "name": "Футболка"
          },
          "optionValues": [
            {
              "id": 1,
              "name": "red",
              "presentation": "Красный",
              "option": {
                "id": 1,
                "name": "color",
                "presentation": "Цвет"
              }
            },
            {
              "id": 4,
              "name": "s",
              "presentation": "S",
              "option": {
                "id": 2,
                "name": "size",
                "presentation": "Размер"
              }
            }
          ]
        }
      }
    ]
  }
}
```

Как правило, на экране корзины нет логики для смены варианта, а необходимо лишь отобразить значения опций, поэтому они выгружены напрямую в вариантах.

Если по дизайну можно поменять вариант товара прямо из корзины, но это действие подразумевает открытие модального окна, то клиент может воспользоваться запросом детальной информации о товаре для получения списка возможных вариантов товара. Если элементы управления для смены варианта находятся прямо в позиции корзины, то в запросе корзины следует выдать информацию о вариантах в таком же виде, как в запросе детальной информации о товаре.
