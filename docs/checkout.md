# Оформление заказа

## Общие положения

Чтобы интернет-магазин принял заказ в обработку, пользователь должен предоставить различную информацию о себе и о заказе. Этот процесс следует за сбором корзины и называется оформлением заказа.

Дизайн оформления заказа в клиентском приложении может сильно отличаться от магазина к магазину, но ниже перечислены две самые популярные схемы:

1. Пользователь должен последовательно двигаться по этапам оформления заказа. Этапы могут быть оформлены отдельными экранами или постепенно появляющимися блоками на одном экране. Пока пользователь не завершит один этап, он не сможет перейти к следующему. Если пользователь вернется к одному из предыдущих этапов, то ему нужно будет пройти следующие этапы заново.

2. Пользователь может вводить данные в любом порядке, независимо друг от друга. В таком случае, все данные оформления заказа находятся на одном экране клиентского приложения и видны все сразу. В зависимости от дизайна, экран может работать в следующих режимах:

    - Экран только отображает данные, а для их редактирования открываются дополнительные экраны.
    - Экран сразу содержит редактируемые поля.

// TODO - скриншоты дизайна для всех схем.

В данном разделе описано, как построить универсальное REST API оформления заказа, подходящее под большинство схем.

## Этапы заказа

Как описано в разделе [Корзина](./cart.md), для заказа и корзины можно использовать одну и ту же сущность, просто напросто меняя её статус. Как минимум, у заказа должны быть начальный и конечный статусы:
- Корзина
- Оформлен

Между ними могут находиться промежуточные статусы, ответственные за определенные этапы оформления заказа.

Для наглядности будет рассмотрен пример, в котором оформление заказа состоит из следующих этапов:

1. Ввод личных данных. Необходимо предоставить информацию о покупателе и получателе:

    - Имя (Строка)
    - Фамилия (Строка)
    - Адрес электронной почты (Строка)
    - Номер телефона (Строка)

2. Выбор способа получения заказа, которые бывают следующих типов:

    - Самовывоз. При этом нужно выбрать пункт самовывоза.
    - Доставка. При этом нужно ввести адрес доставки, состоящий из следующих полей:

      - Страна (Выбор из справочника)
      - Город (Строка)
      - Улица, дом, город (Строка)
      - Комментарий (Строка)

3. Выбор способа оплаты из списка, которые бывают следующих типов:

    - Картой онлайн
    - При получении заказа
    - Google Pay или Apple Pay для мобильных приложений в зависимости от производителя

## Сохранение данных заказа

Для сохранения данных заказа достаточно предоставить один единственный API-запрос. Какие данные в него переданы, такие в базу данных и сохранять.

Каждый блок данных должен быть проверен на корректность перед сохранением. Например, если в адресе доставки есть обязательные поля, но в объекте адреса доставки они не переданы, то сервер должен вернуть соответствующую ошибку.

Запрос не должен автоматически переводить заказ на следующий этап. Но если клиентскому приложению нужна такая возможность, то предоставьте её, например, через передачу соответствующего флага в тело запроса. Клиентское приложение на каждом этапе будет передавать в запрос соответствующие для этого этапа данные и флаг перевода на следующий этап. Если при этом предполагаются какие-либо дополнительные проверки данных, то их нужно провести.

## Перевод заказа на следующий этап

Перевод заказа на следующий этап может предполагать дополнительные проверки.

Например, на этапе "Личные данные" пользователь может независимо друг от друга заполнить покупателя и получателя, но именно в момент перехода на следующий этап нужно дополнительно проверить, что они оба заполнены.

Если дизайн клиентского приложения предполагает последовательное продвижение по этапам, но переход на следующий этап отделен от сохранения данных, то необходимо предоставить API-запрос для перевода заказа на следующий этап.

## Завершение оформления заказа

Если дизайн клиентского приложения предполагает заполнение данных в любом порядке, то необходимо предоставить API-запрос для перевода заказа на максимально возможный этап, в зависимости от валидности данных.

Если все данные прошли проверку, заказ перейдёт в конечный статус и будет считаться оформленным. Если часть данных не прошла проверку, то заказ останется в максимально возможном этапе, для которого данные проверку прошли.

## Структура данных

### Личные данные

Информацию о покупателе и получателе заказа можно хранить в одной таблице - личные данные:

```sql
CREATE TABLE order_people
(
  id bigserial PRIMARY KEY, -- Идентификатор заказа
  first_name character varying, -- Имя
  last_name character varying, -- Фамилия
  email character varying, -- Адрес электронной почты
  phone character varying -- Номер телефона
);
```

Так как пользователь должен указать в заказе покупателя и получателя, нужны соответствующие ссылки в таблице заказов:

```sql
ALTER TABLE orders
ADD COLUMN customer_id bigint;

CREATE INDEX index_orders_on_customer_id
  ON orders
  (customer_id);

ALTER TABLE orders
ADD COLUMN recipient_id bigint;

CREATE INDEX index_orders_on_recipient_id
  ON orders
  (recipient_id);
```

### Получение заказа

Информацию о получении заказа (отгрузках) следует хранить в дополнительной таблице со ссылкой на заказ. Это может пригодиться, если со временем понадобится разбивать доставку на несколько посылок.

Пользователь должен выбрать один из нескольких способов получения заказа, каждый из которых может быть одним из следующих типов:
- Самовывоз
- Доставка

С разделением на способы и типы есть возможность завести несколько разных способов одного типа. Например:
- "Из пункта выдачи" - Самовывоз.
- "Из офиса компании" - Самовывоз.
- "Доставка курьером компании" - Доставка.
- "Доставка компанией-партнёром" - Доставка.

Чтобы при изменении доступных способов получения заказа не пришлось дополнительно программировать, следует хранить их в базе данных в соответствущей таблице.

Каждому способу получения заказа в рамках конкретного заказа может соответсовать собственная стоимость. Чтобы не рассчитывать её каждый раз при выдаче в API, следует хранить соответствие стоимости и способа получения заказа в соответствующей таблице.

Если пользователь выбрал тип "Доставка", то он должен дополнительно ввести адрес доставки, а если тип "Самовывоз" - то выбрать пункт выдачи, доступный для выбранного способа получения.

Пункты выдачи зачастую нужно отображать на географической карте, следовательно, нужно хранить геопозицию. Геопозиции могут вводиться администратором или получаться из API геокодинга со стороны сервера, но ни в коем случае не клиентским приложением.

В связи с этими требованиями можно создать следующую структуру таблиц.

Способы получения заказа:

```sql
CREATE TABLE shipping_methods
(
  id bigserial PRIMARY KEY, -- Идентификатор способа получения заказа,
  type smallint, -- Тип способа получения доставки. 0 - "Самовывоз" и 1 - "Доставка".
  name character varying -- Название способа получения заказа для отображения на клиенте, например, "Доставка до двери" или "Из офиса компании"
);
```

Стоимости способов получения заказа в рамках конкретного заказа:

```sql
CREATE TABLE order_shipping_rates
(
  id bigserial PRIMARY KEY, -- Идентификатор стоимости способа получения заказа
  order_id bigint, -- Идентификатор заказа
  shipping_method_id bigint, -- Идентификатор способа получения заказа
  price number(8, 2) -- Стоимость
);

CREATE INDEX index_order_shipping_rates_on_order_id
  ON order_shipping_rates
  (order_id);

CREATE INDEX index_order_shipping_rates_on_shipping_method_id
  ON order_shipping_rates
  (shipping_method_id);
```

Геопозиции:

```sql
CREATE TABLE locations
(
  id bigserial PRIMARY KEY, -- Идентификатор геопозиции
  latitude real, -- Широта
  longitude real -- Долгота
);
```

Пункты выдачи:

```sql
CREATE TABLE pickup_points
(
  id bigserial PRIMARY KEY, -- Идентификатор пункта выдачи
  name character varying, -- Название пункта выдачи для показа на клиенте
  address character varying, -- Адрес пункта выдачи
  shipping_method_id bigint, -- Идентификатор способа получения заказа, для которого доступен этот пункт выдачи
  location_id bigint -- Идентификатор геопозиции
);

CREATE INDEX index_pickup_points_on_shipping_method_id
  ON pickup_points
  (shipping_method_id);

CREATE INDEX index_pickup_points_on_location_id
  ON pickup_points
  (location_id);
```

Адреса доставки:

```sql
CREATE TABLE delivery_addresses
(
  id bigserial PRIMARY KEY, -- Идентификатор адреса доставки
  country_id bigint, -- Идентификатор страны
  city character varying, -- Город
  line1 character varying, -- Улица, дом, квартира
  comment character varying -- Комментарий к адресу
);

CREATE INDEX index_delivery_addresses
  ON delivery_addresses
  (country_id);
```

Отгрузки (информация о получении конкретного заказа):

```sql
CREATE TABLE shipments
(
  id bigserial PRIMARY KEY, -- Идентификатор отгрузки
  rate_id bigint, -- Идентификатор стоимости способа получения заказа
  delivery_address_id bigint, -- Идентификатор адреса доставки
  pickup_point_id bigint, -- Идентификатор пункта самовывоза
  order_id bigint -- Идентификатор заказа
);

CREATE INDEX index_shipments_on_rate_id
  ON shipments
  (rate_id);

CREATE INDEX index_shipments_on_delivery_address_id
  ON shipments
  (delivery_address_id);

CREATE INDEX index_shipments_on_order_id
  ON shipments
  (order_id);
```

### Информация об оплате

Информацию об оплате следует хранить в дополнительной таблице со ссылкой на заказ. Это может пригодиться, если со временем появится возможность оплачивать заказ по частям. В этой же таблице можно хранить:
- Итоговую сумму платежа.
- Выбранный способ оплаты.
- Статус платежа.

Способы оплаты могут быть разных типов:
- Оффлайн
- Онлайн:
    - Банк
    - Google Pay
    - Apple Pay

У магазина может быть несколько способов оплаты с одним типом. Например, магазин может дать на выбор пользователю следующие оффлайн способы:
- Картой курьеру
- Наличными курьеру

Чтобы при изменении доступных способов оплаты не пришлось дополнительно программировать, следует хранить их в базе данных в соответствущей таблице.

Хранить типы в базе данных не имеет смысла, так как добавление нового типа в любом случае потребует дополнительного программирования.

В связи с этими требованиями можно создать следующую структуру таблиц.

Способы оплаты:

```sql
CREATE TABLE payment_methods
(
  id bigserial PRIMARY KEY, -- Идентификатор способа оплаты
  name character varying, -- Название способа оплаты, например, "Картой онлайн"
  type smallint, -- Тип способа оплаты. 0 - Оффлайн, 1 - Банк, 2 - Google Pay, 3 - Apple Pay
);
```

Платежи:

```sql
CREATE TABLE payments
(
  id bigserial PRIMARY KEY, -- Идентификатор платежа
  order_id bigint, -- Идентификатор заказа
  method_id bigint, -- Идентификатор способа оплаты
  total number(8, 2), -- Стоимость платежа
  status smallint -- Статус платежа. 0 - Требуется оплатить, 1 - Оплачен.
);

CREATE INDEX index_payments_on_order_id
  ON payments
  (order_id);

CREATE INDEX index_payments_on_method_id
  ON payments
  (method_id);
```

### Итоговая стоимость

Часто дизайн клиентского приложения требует показать пользователю детальную информацию о платеже:
- Общую стоимость товаров
- Стоимость доставки
- Итоговую сумму платежа

Итоговая сумма платежа и стоимость доставки уже присутствуют в информации о платеже и в информации о получении заказа соответственно.

Для общей стоимости товаров можно добавить соответствующее поле в заказ, чтобы не делать рассчет каждый раз при выдаче информации в API:

```sql
ALTER TABLE orders
ADD COLUMN items_total number(8, 2);
```

### Выдача информации о текущем заказе в API

Структура данных для сериализации текущего заказа в JSON:

```java
public class Order {
  private Long id;
  private OrderStatus status;
  private Price itemsTotal;
  private OrderPerson customer;
  private OrderPerson recipient;
  private Shipment shipment;
  private Payment payment;
}

public enum OrderStatus {
  CART(0, "cart"),
  PERSONAL_INFO(1, "personal_info"),
  SHIPMENT(2, "shipment"),
  PAYMENT(3, "payment"),
  COMPLETE(4, "complete");

  private final int value;
  private final String name;

  OrderStatus(int value, String name) {
    this.value = value;
    this.name = name;
  }
}

public class OrderPerson {
  private Long id;
  private String firstName;
  private String lastName;
  private String email;
  private String phone;
}

public class Shipment {
  private Long id;
  private ShippingRate rate;
  private DeliveryAddress deliveryAddress;
  private PickupPoint pickupPoint;
}

public class ShippingRate {
  private Long id;
  private Price price;
  private ShippingMethod shippingMethod;
}

public class ShippingMethod {
  private Long id;
  private String name;
  private ShippingMethodType type;
}

public enum ShippingMethodType {
  PICKUP(0, "pickup"),
  DELIVERY(1, "delivery");

  private final int value;
  private final String name;

  ShippingMethodType(int value, String name) {
    this.value = value;
    this.name = name;
  }
}

public class DeliveryAddress {
  private Long id;
  private Country country;
  private String city;
  private String line1;
  private String comment;
}

public class Country {
  private Long id;
  private String name;
}

public class PickupPoint {
  private Long id;
  private String name;
  private String address;
  private Location location;
}

public class Location {
  private Long id;
  private Float latitude;
  private Float longitude;
}

public class Payment {
  private Long id;
  private PaymentStatus status;
  private PaymentMethod method;
  private Price total;
}

public enum PaymentStatus {
  REQUIRED(0, "required"),
  PAID(1, "paid");

  private final int value;
  private final String name;

  PaymentStatus(int value, String name) {
    this.value = value;
    this.name = name;
  }
}

public class PaymentMethod {
  private Long id;
  private String name;
  private PaymentMethodType type;
}

public enum PaymentMethodType {
  OFFLINE(0, "offline"),
  BANK(1, "bank"),
  GOOGLE_PAY(2, "google_pay"),
  APPLE_PAY(3, "apple_pay");

  private final int value;
  private final String name;

  PaymentMethodType(int value, String name) {
    this.value = value;
    this.name = name;
  }
}

public class Price {
  private BigDecimal amount;
}
```

Пример JSON-а с информацией о текущем заказе для клиентского приложения:

```json
{
  "order": {
    "id": 1,
    "status": "cart",
    "itemsTotal": {
      "amount": "100.00"
    },
    "customer": {
      "id": 1,
      "firstName": "Гарри",
      "lastName": "Поттер",
      "email": "harrypotter@hogwarts.com",
      "phone": "1234567890"
    },
    "recipient": {
      "id": 1,
      "firstName": "Гарри",
      "lastName": "Поттер",
      "email": "harrypotter@hogwarts.com",
      "phone": "1234567890"
    },
    "shipment": {
      "id": 1,
      "rate": {
        "id": 1,
        "price": {
          "amount": "50.00"
        },
        "shippingMethod": {
          "id": 1,
          "name": "Совой в руки",
          "type": "pickup"
        }
      },
      "deliveryAddress": {
        "id": 1,
        "countryId": 1,
        "city": "Литтл Уингинг",
        "line1": "ул. Тисовая, д. 4",
        "comment": "В чулан под лестницей"
      },
      "pickupPoint": {
        "id": 1,
        "name": "Magic Box в \"Всё для квиддича\"",
        "address": "Косой переулок, магазин \"Всё для квиддича\"",
        "location": {
          "id": 1,
          "latitude": 51.215485,
          "longitude": -0.631027
        }
      }
    },
    "payment": {
      "id": 1,
      "status": "required",
      "method": {
        "id": 1,
        "name": "Картой онлайн",
        "type": "bank"
      },
      "total": {
        "amount": "150.00"
      }
    }
  }
}
```
