CLASS zik_cl_fx_seed DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.

CLASS zik_cl_fx_seed IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.

    DELETE FROM zik_a_fxrate.

    INSERT zik_a_fxrate FROM TABLE @( VALUE #(
      ( from_currency = 'PLN' to_currency = 'EUR' rate = '0.230000' )
      ( from_currency = 'USD' to_currency = 'EUR' rate = '0.920000' )
      ( from_currency = 'GBP' to_currency = 'EUR' rate = '1.170000' )
      ( from_currency = 'CZK' to_currency = 'EUR' rate = '0.040000' )
      ( from_currency = 'UAH' to_currency = 'EUR' rate = '0.022000' ) ) ).

    out->write( |FX rates inserted: { sy-dbcnt }| ).

  ENDMETHOD.
ENDCLASS.
