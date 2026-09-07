CLASS zik_cl_ccy_test DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    TYPES ts_reported TYPE RESPONSE FOR REPORTED zik_i_credapp.

    DATA out TYPE REF TO if_oo_adt_classrun_out.

    METHODS dump_messages
      IMPORTING label    TYPE string
                reported TYPE ts_reported.
ENDCLASS.


CLASS zik_cl_ccy_test IMPLEMENTATION.

  METHOD dump_messages.
    LOOP AT reported-creditapplication INTO DATA(line).
      IF line-%msg IS BOUND.
        out->write( |{ label } msg: { line-%msg->if_message~get_text( ) }| ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    me->out = out.

    DATA(app_id) = CONV zik_a_credapp-application_id( '0000000031' ).

    out->write( '=== v3 draft test ===' ).

    MODIFY ENTITIES OF zik_i_credapp
      ENTITY CreditApplication
        EXECUTE Edit FROM VALUE #( ( %cid          = 'EDIT1'
                                     ApplicationId = app_id ) )
      FAILED   DATA(edit_failed)
      REPORTED DATA(edit_reported).

    out->write( |Edit failed lines: { lines( edit_failed-creditapplication ) }| ).
    dump_messages( label = 'Edit' reported = edit_reported ).

    READ ENTITIES OF zik_i_credapp
      ENTITY CreditApplication
        FIELDS ( CurrencyCode TotalIncome )
        WITH VALUE #( ( %is_draft     = if_abap_behv=>mk-on
                        ApplicationId = app_id ) )
      RESULT DATA(before).

    IF before IS INITIAL.
      out->write( 'no draft instance available' ).
      RETURN.
    ENDIF.

    out->write( |DRAFT BEFORE  ccy={ before[ 1 ]-CurrencyCode } total={ before[ 1 ]-TotalIncome }| ).

    DATA(new_ccy) = COND zik_a_credapp-currency_code(
                      WHEN before[ 1 ]-CurrencyCode = 'EUR' THEN 'USD' ELSE 'EUR' ).

    out->write( |switching draft currency to { new_ccy }| ).

    MODIFY ENTITIES OF zik_i_credapp
      ENTITY CreditApplication
        UPDATE FIELDS ( CurrencyCode )
        WITH VALUE #( ( %is_draft     = if_abap_behv=>mk-on
                        ApplicationId = app_id
                        CurrencyCode  = new_ccy ) )
      FAILED   DATA(upd_failed)
      REPORTED DATA(upd_reported).

    out->write( |Update failed lines: { lines( upd_failed-creditapplication ) }| ).
    dump_messages( label = 'Update' reported = upd_reported ).

    READ ENTITIES OF zik_i_credapp
      ENTITY CreditApplication
        FIELDS ( CurrencyCode TotalIncome )
        WITH VALUE #( ( %is_draft     = if_abap_behv=>mk-on
                        ApplicationId = app_id ) )
      RESULT DATA(after).

    out->write( |DRAFT AFTER   ccy={ after[ 1 ]-CurrencyCode } total={ after[ 1 ]-TotalIncome }| ).

    MODIFY ENTITIES OF zik_i_credapp
      ENTITY CreditApplication
        EXECUTE Discard FROM VALUE #( ( ApplicationId = app_id ) )
      FAILED   DATA(disc_failed)
      REPORTED DATA(disc_reported).

    out->write( |Discard failed lines: { lines( disc_failed-creditapplication ) } (draft cleaned up)| ).

  ENDMETHOD.

ENDCLASS.

