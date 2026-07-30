CLASS zik_cl_det_test DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.

CLASS zik_cl_det_test IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.

    " ---- 1. CREATE with product CONSUMER ----
    MODIFY ENTITIES OF zik_i_credapp
      ENTITY CreditApplication
        CREATE FIELDS ( CustomerId ProductId Amount TermMonths CurrencyCode )
          WITH VALUE #( ( %cid       = 'C1'
                          CustomerId = '00000001'
                          ProductId  = 'CONSUMER'
                          Amount     = '10000.00'
                          TermMonths = '012'
                          CurrencyCode = 'EUR' ) )
      MAPPED DATA(mapped)
      FAILED DATA(failed_create)
      REPORTED DATA(reported_create).

    COMMIT ENTITIES RESPONSE OF zik_i_credapp
      FAILED DATA(commit_failed)
      REPORTED DATA(commit_reported).

    IF mapped-creditapplication IS INITIAL.
      out->write( 'CREATE failed' ).
      out->write( failed_create ).
      RETURN.
    ENDIF.

    DATA(new_key) = mapped-creditapplication[ 1 ]-%key.
    out->write( |Created ApplicationId = { new_key-ApplicationId }| ).

    " ---- 2. READ after create ----
    READ ENTITIES OF zik_i_credapp
      ENTITY CreditApplication
        FIELDS ( ProductId InterestRate MonthlyPayment Status )
        WITH VALUE #( ( %key = new_key ) )
      RESULT DATA(after_create).
    out->write( '--- after CREATE (expect CONSUMER, rate 15.9) ---' ).
    out->write( after_create ).

    " ---- 3. UPDATE product -> MORTGAGE ----
    MODIFY ENTITIES OF zik_i_credapp
      ENTITY CreditApplication
        UPDATE FIELDS ( ProductId )
          WITH VALUE #( ( %key = new_key ProductId = 'MORTGAGE' ) )
      FAILED DATA(failed_upd)
      REPORTED DATA(reported_upd).

    COMMIT ENTITIES RESPONSE OF zik_i_credapp
      FAILED DATA(commit_failed2)
      REPORTED DATA(commit_reported2).

    " ---- 4. READ after update ----
    READ ENTITIES OF zik_i_credapp
      ENTITY CreditApplication
        FIELDS ( ProductId InterestRate MonthlyPayment Status )
        WITH VALUE #( ( %key = new_key ) )
      RESULT DATA(after_update).
    out->write( '--- after UPDATE product=MORTGAGE (expect rate 8.5 if on-modify works) ---' ).
    out->write( after_update ).

  ENDMETHOD.
ENDCLASS.
