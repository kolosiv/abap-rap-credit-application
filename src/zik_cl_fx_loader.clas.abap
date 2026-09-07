CLASS zik_cl_fx_loader DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    TYPES: BEGIN OF ty_result,
             success   TYPE abap_bool,
             pairs     TYPE i,
             rate_date TYPE d,
             message   TYPE string,
           END OF ty_result.

    METHODS load_rates
      RETURNING VALUE(result) TYPE ty_result.

  PRIVATE SECTION.
    CONSTANTS api_url TYPE string
      VALUE `https://api.frankfurter.dev/v1/latest?from=EUR&to=USD,GBP,PLN,CZK,CHF`.

    TYPES: BEGIN OF ty_rates,
             usd TYPE decfloat34,
             gbp TYPE decfloat34,
             pln TYPE decfloat34,
             czk TYPE decfloat34,
             chf TYPE decfloat34,
           END OF ty_rates.

    TYPES: BEGIN OF ty_payload,
             amount TYPE decfloat34,
             base   TYPE string,
             date   TYPE string,
             rates  TYPE ty_rates,
           END OF ty_payload.

    TYPES: BEGIN OF ty_eur_rate,
             currency TYPE zik_a_fxrate-from_currency,
             rate     TYPE decfloat34,
           END OF ty_eur_rate.

    TYPES tt_eur_rate TYPE STANDARD TABLE OF ty_eur_rate WITH EMPTY KEY.
    TYPES tt_fxrate   TYPE STANDARD TABLE OF zik_a_fxrate WITH EMPTY KEY.

    METHODS fetch
      EXPORTING status TYPE i
                body   TYPE string
      RAISING   cx_http_dest_provider_error
                cx_web_http_client_error
                cx_web_message_error.

    METHODS expand_pairs
      IMPORTING eur_rates    TYPE tt_eur_rate
                for_date     TYPE d
      RETURNING VALUE(rates) TYPE tt_fxrate.
ENDCLASS.


CLASS zik_cl_fx_loader IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    DATA(outcome) = load_rates( ).

    IF outcome-success = abap_true.
      out->write( |{ outcome-pairs } rates loaded, date { outcome-rate_date DATE = ISO }| ).
    ELSE.
      out->write( |FX load failed: { outcome-message }| ).
    ENDIF.

  ENDMETHOD.

  METHOD load_rates.

    DATA payload TYPE ty_payload.

    TRY.
        fetch( IMPORTING status = DATA(status)
                         body   = DATA(body) ).

        IF status <> 200.
          result-message = |HTTP { status }: { body }|.
          RETURN.
        ENDIF.

        xco_cp_json=>data->from_string( body )->write_to( REF #( payload ) ).

      CATCH cx_root INTO DATA(error).
        result-message = error->get_text( ).
        RETURN.
    ENDTRY.

    IF payload-rates-usd IS INITIAL.
      result-message = |Unexpected payload: { body }|.
      RETURN.
    ENDIF.

    DATA(date_iso) = payload-date.
    REPLACE ALL OCCURRENCES OF '-' IN date_iso WITH ``.
    DATA(rate_date) = CONV d( date_iso ).

    DATA(eur_rates) = VALUE tt_eur_rate(
      ( currency = 'EUR' rate = 1 )
      ( currency = 'USD' rate = payload-rates-usd )
      ( currency = 'GBP' rate = payload-rates-gbp )
      ( currency = 'PLN' rate = payload-rates-pln )
      ( currency = 'CZK' rate = payload-rates-czk )
      ( currency = 'CHF' rate = payload-rates-chf ) ).

    DATA(rates) = expand_pairs( eur_rates = eur_rates
                                for_date  = rate_date ).

    DELETE FROM zik_a_fxrate.
    INSERT zik_a_fxrate FROM TABLE @rates.

    result = VALUE #( success   = abap_true
                      pairs     = lines( rates )
                      rate_date = rate_date ).

  ENDMETHOD.

  METHOD fetch.

    DATA(destination) = cl_http_destination_provider=>create_by_url( api_url ).
    DATA(client)      = cl_web_http_client_manager=>create_by_http_destination( destination ).

    client->get_http_request( )->set_header_field( i_name  = 'Accept'
                                                   i_value = 'application/json' ).

    DATA(response) = client->execute( if_web_http_client=>get ).

    status = response->get_status( )-code.
    body   = response->get_text( ).

    client->close( ).

  ENDMETHOD.

  METHOD expand_pairs.

    LOOP AT eur_rates INTO DATA(base_ccy).
      LOOP AT eur_rates INTO DATA(quote_ccy).
        APPEND VALUE #( from_currency = base_ccy-currency
                        to_currency   = quote_ccy-currency
                        rate          = quote_ccy-rate / base_ccy-rate
                        rate_date     = for_date ) TO rates.
      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

