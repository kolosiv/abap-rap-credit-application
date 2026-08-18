CLASS zik_cl_det_test DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.



CLASS ZIK_CL_DET_TEST IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    " ---- 1. CREATE application together with one income (create by association) ----
    MODIFY ENTITIES OF zik_i_credapp
      ENTITY CreditApplication
        CREATE FIELDS ( CustomerId ProductId Amount TermMonths CurrencyCode )
          WITH VALUE #( ( %cid         = 'APP1'
                          CustomerId   = '00000001'
                          ProductId    = 'CONSUMER'
                          Amount       = '20000.00'
                          TermMonths   = '024'
                          CurrencyCode = 'EUR' ) )
        CREATE BY \_Income
          FIELDS ( IncomeType MonthlyAmount CurrencyCode )
          WITH VALUE #( ( %cid_ref = 'APP1'
                          %target  = VALUE #( ( %cid          = 'INC1'
                                                IncomeType    = 'SA'
                                                MonthlyAmount = '3000.00'
                                                CurrencyCode  = 'EUR' ) ) ) )
      MAPPED DATA(mapped)
      FAILED DATA(failed_create)
      REPORTED DATA(reported_create).

    IF mapped-creditapplication IS INITIAL.
      out->write( 'CREATE failed' ).
      out->write( failed_create ).
      out->write( reported_create ).
      RETURN.
    ENDIF.

    DATA(new_key) = mapped-creditapplication[ 1 ]-%key.
    out->write( |Created ApplicationId = { new_key-ApplicationId }| ).

    COMMIT ENTITIES RESPONSE OF zik_i_credapp
      FAILED DATA(commit_failed)
      REPORTED DATA(commit_reported).

    IF commit_failed IS NOT INITIAL.
      out->write( 'COMMIT failed - validations blocked the save:' ).
      out->write( commit_failed ).
      out->write( commit_reported ).
    ELSE.
      out->write( 'COMMIT ok' ).
    ENDIF.

    " ---- 2. read back what the determinations produced ----
    READ ENTITIES OF zik_i_credapp
      ENTITY CreditApplication
        FIELDS ( Amount TermMonths InterestRate MonthlyPayment TotalIncome Status )
        WITH VALUE #( ( %key = new_key ) )
      RESULT DATA(after).

    out->write( '--- expect InterestRate 15.9, MonthlyPayment ~975, TotalIncome 3000 ---' ).
    out->write( after ).

    " ---- 3. read the children ----
    READ ENTITIES OF zik_i_credapp
      ENTITY CreditApplication BY \_Income
        ALL FIELDS WITH VALUE #( ( %key = new_key ) )
      RESULT DATA(incomes).

    out->write( '--- incomes of that application ---' ).
    out->write( incomes ).

  ENDMETHOD.
ENDCLASS.
