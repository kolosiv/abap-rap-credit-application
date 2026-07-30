CLASS lhc_credapp DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR CreditApplication
      RESULT result.
    METHODS setInitialStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR CreditApplication~setInitialStatus.
    METHODS copyInterestRate FOR DETERMINE ON MODIFY
      IMPORTING keys FOR CreditApplication~copyInterestRate.
    METHODS calculateMonthlyPayment FOR DETERMINE ON MODIFY
      IMPORTING keys FOR CreditApplication~calculateMonthlyPayment.

    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE CreditApplication.
    METHODS earlynumbering_cba_Income FOR NUMBERING
      IMPORTING entities FOR CREATE CreditApplication\_Income.
ENDCLASS.

CLASS lhc_credapp IMPLEMENTATION.

  METHOD get_global_authorizations.
    " TEMP scaffold to satisfy strict(2). Wave 5: replace with real authorization.
    result-%create = if_abap_behv=>auth-allowed.
    result-%update = if_abap_behv=>auth-allowed.
    result-%delete = if_abap_behv=>auth-allowed.
  ENDMETHOD.

  METHOD earlynumbering_create.
    DATA lv_id TYPE zik_a_credapp-application_id.

    LOOP AT entities INTO DATA(entity) WHERE ApplicationId IS NOT INITIAL.
      APPEND VALUE #( %cid = entity-%cid %key = entity-%key %is_draft = entity-%is_draft )
             TO mapped-creditapplication.
    ENDLOOP.

    DATA(entities_wo_id) = entities.
    DELETE entities_wo_id WHERE ApplicationId IS NOT INITIAL.
    IF entities_wo_id IS INITIAL.
      RETURN.
    ENDIF.

    TRY.
        cl_numberrange_runtime=>number_get(
          EXPORTING
            nr_range_nr       = '01'
            object            = 'ZIK_CRDAPP'
            quantity          = CONV #( lines( entities_wo_id ) )
          IMPORTING
            number            = DATA(lv_top)
            returned_quantity = DATA(lv_qty) ).
      CATCH cx_number_ranges INTO DATA(lx).
        LOOP AT entities_wo_id INTO entity.
          APPEND VALUE #( %cid = entity-%cid %key = entity-%key %is_draft = entity-%is_draft
                          %msg = lx ) TO reported-creditapplication.
          APPEND VALUE #( %cid = entity-%cid %key = entity-%key %is_draft = entity-%is_draft )
                 TO failed-creditapplication.
        ENDLOOP.
        RETURN.
    ENDTRY.

    lv_id = lv_top - lv_qty.
    LOOP AT entities_wo_id INTO entity.
      lv_id += 1.
      entity-ApplicationId = lv_id.
      APPEND VALUE #( %cid = entity-%cid %key = entity-%key %is_draft = entity-%is_draft )
             TO mapped-creditapplication.
    ENDLOOP.
  ENDMETHOD.

  METHOD earlynumbering_cba_Income.
    DATA max_income_id TYPE zik_a_income-income_id.

    READ ENTITIES OF zik_i_credapp IN LOCAL MODE
      ENTITY CreditApplication BY \_Income
        FROM CORRESPONDING #( entities )
        LINK DATA(incomes).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<app_group>) GROUP BY <app_group>-ApplicationId.

      max_income_id = REDUCE #( INIT max = CONV zik_a_income-income_id( '0' )
                                FOR inc IN incomes USING KEY entity
                                     WHERE ( source-ApplicationId = <app_group>-ApplicationId )
                                NEXT max = COND zik_a_income-income_id(
                                                  WHEN inc-target-IncomeId > max
                                                  THEN inc-target-IncomeId
                                                  ELSE max ) ).

      LOOP AT GROUP <app_group> ASSIGNING FIELD-SYMBOL(<app>).
        LOOP AT <app>-%target ASSIGNING FIELD-SYMBOL(<income_wo_id>).
          APPEND CORRESPONDING #( <income_wo_id> ) TO mapped-income ASSIGNING FIELD-SYMBOL(<mapped_income>).
          IF <income_wo_id>-IncomeId IS INITIAL.
            max_income_id += 10.
            <mapped_income>-IncomeId = max_income_id.
          ENDIF.
        ENDLOOP.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD setInitialStatus.

    READ ENTITIES OF zik_i_credapp IN LOCAL MODE
      ENTITY CreditApplication
        FIELDS ( Status )
        WITH CORRESPONDING #( keys )
      RESULT DATA(credapps).

    DELETE credapps WHERE Status IS NOT INITIAL.
    IF credapps IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zik_i_credapp IN LOCAL MODE
      ENTITY CreditApplication
        UPDATE FIELDS ( Status )
        WITH VALUE #( FOR ca IN credapps ( %tky   = ca-%tky
                                           Status = 'DR' ) )
      REPORTED DATA(update_reported).

    reported = CORRESPONDING #( DEEP update_reported ).

  ENDMETHOD.

  METHOD copyInterestRate.

    READ ENTITIES OF zik_i_credapp IN LOCAL MODE
        ENTITY CreditApplication
          FIELDS ( ProductId )
          WITH CORRESPONDING #( keys )
        RESULT DATA(credapps).

    DELETE credapps WHERE ProductId IS INITIAL.
    IF credapps IS INITIAL.
      RETURN.
    ENDIF.

    SELECT ProductId, InterestRate
      FROM zik_i_product
      FOR ALL ENTRIES IN @credapps
      WHERE ProductId = @credapps-ProductId
      INTO TABLE @DATA(products).

    MODIFY ENTITIES OF zik_i_credapp IN LOCAL MODE
      ENTITY CreditApplication
        UPDATE FIELDS ( InterestRate )
        WITH VALUE #( FOR ca IN credapps
                      ( %tky         = ca-%tky
                        InterestRate = VALUE #( products[ ProductId = ca-ProductId ]-InterestRate OPTIONAL ) ) )
      REPORTED DATA(update_reported).

    reported = CORRESPONDING #( DEEP update_reported ).

  ENDMETHOD.

  METHOD calculateMonthlyPayment.

    READ ENTITIES OF zik_i_credapp IN LOCAL MODE
      ENTITY CreditApplication
        FIELDS ( Amount TermMonths InterestRate )
        WITH CORRESPONDING #( keys )
      RESULT DATA(credapps).

    LOOP AT credapps ASSIGNING FIELD-SYMBOL(<credapps>).
      IF <credapps>-Amount = 0 OR <credapps>-TermMonths = 0.
        <credapps>-MonthlyPayment = 0.
      ELSEIF <credapps>-InterestRate = 0.
        <credapps>-MonthlyPayment = <credapps>-Amount / <credapps>-TermMonths.
      ELSE.
        DATA(i) = CONV decfloat34( <credapps>-InterestRate ) / 12 / 100.
        <credapps>-MonthlyPayment = <credapps>-Amount * i / ( 1 - ( 1 + i ) ** ( -1 * <credapps>-TermMonths ) ).
      ENDIF.
    ENDLOOP.

    MODIFY ENTITIES OF zik_i_credapp IN LOCAL MODE
        ENTITY CreditApplication
        UPDATE FIELDS ( MonthlyPayment )
        WITH VALUE #( FOR ca IN credapps
                      ( %tky         = ca-%tky
                        MonthlyPayment = ca-MonthlyPayment ) )
        REPORTED DATA(update_reported).

    reported = CORRESPONDING #( DEEP update_reported ).

  ENDMETHOD.

ENDCLASS.

CLASS lhc_income DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS calculateTotalIncome FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Income~calculateTotalIncome.
ENDCLASS.

CLASS lhc_income IMPLEMENTATION.

  METHOD calculateTotalIncome.

    DATA(credinc) = keys.
    SORT credinc BY ApplicationId ASCENDING.
    DELETE ADJACENT DUPLICATES FROM credinc COMPARING ApplicationId.

    READ ENTITIES OF zik_i_credapp IN LOCAL MODE
      ENTITY CreditApplication
        FIELDS ( CurrencyCode )
        WITH CORRESPONDING #( credinc )
      RESULT DATA(credapps).

    READ ENTITIES OF zik_i_credapp IN LOCAL MODE
      ENTITY CreditApplication BY \_Income
        ALL FIELDS WITH CORRESPONDING #( credapps )
      RESULT DATA(incomes).

    SELECT from_currency, to_currency, rate FROM zik_a_fxrate INTO TABLE @DATA(rates).

    LOOP AT credapps ASSIGNING FIELD-SYMBOL(<credapps>).
      DATA totalamount TYPE zik_a_credapp-total_income.
      CLEAR totalamount.

      LOOP AT incomes ASSIGNING FIELD-SYMBOL(<incomes>)
          WHERE ApplicationId = <credapps>-ApplicationId.
        DATA monthlyamount TYPE zik_a_credapp-total_income.
        IF <incomes>-CurrencyCode <> <credapps>-CurrencyCode.
          DATA(rate) = VALUE #( rates[ from_currency = <incomes>-CurrencyCode
                                       to_currency   = <credapps>-CurrencyCode ]-rate OPTIONAL ).
          monthlyamount = <incomes>-MonthlyAmount * rate.
        ELSE.
          monthlyamount = <incomes>-MonthlyAmount.
        ENDIF.
        totalamount = totalamount + monthlyamount.
      ENDLOOP.

      <credapps>-TotalIncome = totalamount.
    ENDLOOP.

    MODIFY ENTITIES OF zik_i_credapp IN LOCAL MODE
      ENTITY CreditApplication
        UPDATE FIELDS ( TotalIncome )
        WITH VALUE #( FOR ca IN credapps
                      ( %tky        = ca-%tky
                        TotalIncome = ca-TotalIncome ) )
      REPORTED DATA(update_reported).

    reported = CORRESPONDING #( DEEP update_reported ).

  ENDMETHOD.

ENDCLASS.
