CLASS zik_cl_demo_data DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.

CLASS zik_cl_demo_data IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    " справочник клиентов
    DELETE FROM zik_a_customer.
    INSERT zik_a_customer FROM TABLE @( VALUE #(
      ( customer_id = '00000001' first_name = 'Anna'   last_name = 'Kowalski' birth_date = '19880412' )
      ( customer_id = '00000002' first_name = 'Marek'  last_name = 'Nowak'    birth_date = '19950827' )
      ( customer_id = '00000003' first_name = 'Elena'  last_name = 'Volkova'  birth_date = '19790103' )
      ( customer_id = '00000004' first_name = 'Tomas'  last_name = 'Horak'    birth_date = '19911119' )
      ( customer_id = '00000005' first_name = 'Sofia'  last_name = 'Marchenko' birth_date = '20000205' )
    ) ).
    out->write( |Customers inserted: { sy-dbcnt }| ).

    " справочник кредитных продуктов
    DELETE FROM zik_a_product.
    INSERT zik_a_product FROM TABLE @( VALUE #(
      ( product_id = 'MORTGAGE'  description = 'Mortgage loan'
        min_amount = '50000.00'  max_amount = '1000000.00' currency_code = 'EUR'
        min_term_months = '060'  max_term_months = '360'   interest_rate = '8.500' )
      ( product_id = 'CONSUMER'  description = 'Consumer loan'
        min_amount = '1000.00'   max_amount = '50000.00'   currency_code = 'EUR'
        min_term_months = '006'  max_term_months = '060'   interest_rate = '15.900' )
      ( product_id = 'AUTO'      description = 'Car loan'
        min_amount = '5000.00'   max_amount = '150000.00'  currency_code = 'EUR'
        min_term_months = '012'  max_term_months = '084'   interest_rate = '11.250' )
    ) ).
    out->write( |Products inserted: { sy-dbcnt }| ).

  ENDMETHOD.

ENDCLASS.
