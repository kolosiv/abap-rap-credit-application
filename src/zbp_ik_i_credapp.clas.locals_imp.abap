CLASS lhc_credapp DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    CONSTANTS dti_limit_percent TYPE i VALUE 50.

    CONSTANTS: BEGIN OF state_area,
                 product  TYPE string VALUE 'VALIDATE_PRODUCT',
                 customer TYPE string VALUE 'VALIDATE_CUSTOMER',
                 amount   TYPE string VALUE 'VALIDATE_AMOUNT',
                 term     TYPE string VALUE 'VALIDATE_TERM',
                 dti      TYPE string VALUE 'VALIDATE_DTI',
               END OF state_area.

    CONSTANTS: BEGIN OF status,
                 draft     TYPE zik_a_credapp-status VALUE 'DR',
                 submitted TYPE zik_a_credapp-status VALUE 'SU',
                 approved  TYPE zik_a_credapp-status VALUE 'AP',
                 rejected  TYPE zik_a_credapp-status VALUE 'RJ',
               END OF status.

    TYPES tt_decide_keys   TYPE TABLE FOR ACTION IMPORT zik_i_credapp~Approve.
    TYPES tt_decide_result TYPE TABLE FOR ACTION RESULT zik_i_credapp~Approve.
    TYPES ts_failed        TYPE RESPONSE FOR FAILED zik_i_credapp.
    TYPES ts_reported      TYPE RESPONSE FOR REPORTED zik_i_credapp.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR CreditApplication
      RESULT result.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR CreditApplication RESULT result.
    METHODS setInitialStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR CreditApplication~setInitialStatus.
    METHODS copyInterestRate FOR DETERMINE ON MODIFY
      IMPORTING keys FOR CreditApplication~copyInterestRate.
    METHODS calculateMonthlyPayment FOR DETERMINE ON MODIFY
      IMPORTING keys FOR CreditApplication~calculateMonthlyPayment.
    METHODS validateProduct FOR VALIDATE ON SAVE
      IMPORTING keys FOR CreditApplication~validateProduct.
    METHODS validateCustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR CreditApplication~validateCustomer.
    METHODS validateAmount FOR VALIDATE ON SAVE
      IMPORTING keys FOR CreditApplication~validateAmount.
    METHODS validateTerm FOR VALIDATE ON SAVE
      IMPORTING keys FOR CreditApplication~validateTerm.
    METHODS validateDTI FOR VALIDATE ON SAVE
      IMPORTING keys FOR CreditApplication~validateDTI.
    METHODS Submit FOR MODIFY
      IMPORTING keys FOR ACTION CreditApplication~Submit RESULT result.
    METHODS Approve FOR MODIFY
      IMPORTING keys FOR ACTION CreditApplication~Approve RESULT result.
    METHODS Reject FOR MODIFY
      IMPORTING keys FOR ACTION CreditApplication~Reject RESULT result.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR CreditApplication RESULT result.

    METHODS decide
      IMPORTING keys       TYPE tt_decide_keys
                new_status TYPE zik_a_credapp-status
      EXPORTING result     TYPE tt_decide_result
      CHANGING  failed     TYPE ts_failed
                reported   TYPE ts_reported.

    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE CreditApplication.
    METHODS earlynumbering_cba_Income FOR NUMBERING
      IMPORTING entities FOR CREATE CreditApplication\_Income.
ENDCLASS.

CLASS lhc_credapp IMPLEMENTATION.

  METHOD get_global_authorizations.
    result-%create = if_abap_behv=>auth-allowed.
    result-%update = if_abap_behv=>auth-allowed.
    result-%delete = if_abap_behv=>auth-allowed.
  ENDMETHOD.

  METHOD get_instance_features.

    READ ENTITIES OF zik_i_credapp IN LOCAL MODE
      ENTITY CreditApplication
        FIELDS ( Status )
        WITH CORRESPONDING #( keys )
      RESULT DATA(credapps).

    result = VALUE #( FOR ca IN credapps
                      ( %tky              = ca-%tky

                        %features-%update = COND #( WHEN ca-Status <> status-approved
                                                     AND ca-Status <> status-rejected
                                                    THEN if_abap_behv=>fc-o-enabled
                                                    ELSE if_abap_behv=>fc-o-disabled )

                        %action-Edit      = COND #( WHEN ca-Status <> status-approved
                                                     AND ca-Status <> status-rejected
                                                    THEN if_abap_behv=>fc-o-enabled
                                                    ELSE if_abap_behv=>fc-o-disabled )

                        %features-%delete = COND #( WHEN ca-Status = status-draft
                                                    THEN if_abap_behv=>fc-o-enabled
                                                    ELSE if_abap_behv=>fc-o-disabled )

                        %action-Submit    = COND #( WHEN ca-Status = status-draft
                                                    THEN if_abap_behv=>fc-o-enabled
                                                    ELSE if_abap_behv=>fc-o-disabled )

                        %action-Approve   = COND #( WHEN ca-Status = status-submitted
                                                    THEN if_abap_behv=>fc-o-enabled
                                                    ELSE if_abap_behv=>fc-o-disabled )

                        %action-Reject    = COND #( WHEN ca-Status = status-submitted
                                                    THEN if_abap_behv=>fc-o-enabled
                                                    ELSE if_abap_behv=>fc-o-disabled ) ) ).

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
                                           Status = status-draft ) )
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

  METHOD validateProduct.

    READ ENTITIES OF zik_i_credapp IN LOCAL MODE
      ENTITY CreditApplication
        FIELDS ( ProductId )
        WITH CORRESPONDING #( keys )
      RESULT DATA(credapps).

    LOOP AT credapps ASSIGNING FIELD-SYMBOL(<ca>).
      APPEND VALUE #( %tky        = <ca>-%tky
                      %state_area = state_area-product ) TO reported-creditapplication.
    ENDLOOP.

    DATA(credprod) = credapps.
    DELETE credprod WHERE ProductId IS INITIAL.
    IF credprod IS NOT INITIAL.
      SELECT ProductId
        FROM zik_i_product WITH PRIVILEGED ACCESS
        FOR ALL ENTRIES IN @credprod
        WHERE ProductId = @credprod-ProductId
        INTO TABLE @DATA(products).
    ENDIF.

    LOOP AT credapps ASSIGNING FIELD-SYMBOL(<credapp>).
      IF <credapp>-ProductId IS INITIAL.
        APPEND VALUE #( %tky = <credapp>-%tky ) TO failed-creditapplication.
        APPEND VALUE #( %tky              = <credapp>-%tky
                        %state_area       = state_area-product
                        %msg              = new_message( id       = 'ZIK_CREDAPP'
                                                         number   = '001'
                                                         severity = if_abap_behv_message=>severity-error )
                        %element-ProductId = if_abap_behv=>mk-on ) TO reported-creditapplication.
      ELSEIF NOT line_exists( products[ ProductId = <credapp>-ProductId ] ).
        APPEND VALUE #( %tky = <credapp>-%tky ) TO failed-creditapplication.
        APPEND VALUE #( %tky              = <credapp>-%tky
                        %state_area       = state_area-product
                        %msg              = new_message( id       = 'ZIK_CREDAPP'
                                                         number   = '002'
                                                         severity = if_abap_behv_message=>severity-error
                                                         v1       = <credapp>-ProductId )
                        %element-ProductId = if_abap_behv=>mk-on ) TO reported-creditapplication.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD validateCustomer.

    READ ENTITIES OF zik_i_credapp IN LOCAL MODE
    ENTITY CreditApplication
      FIELDS ( CustomerId )
      WITH CORRESPONDING #( keys )
    RESULT DATA(credapps).

    LOOP AT credapps ASSIGNING FIELD-SYMBOL(<ca>).
      APPEND VALUE #( %tky        = <ca>-%tky
                      %state_area = state_area-customer ) TO reported-creditapplication.
    ENDLOOP.

    DATA(credcust) = credapps.
    DELETE credcust WHERE CustomerId IS INITIAL.
    IF credcust IS NOT INITIAL.
      SELECT CustomerId
        FROM zik_i_customer WITH PRIVILEGED ACCESS
        FOR ALL ENTRIES IN @credcust
        WHERE CustomerId = @credcust-CustomerId
        INTO TABLE @DATA(customers).
    ENDIF.

    LOOP AT credapps ASSIGNING FIELD-SYMBOL(<credapp>).
      IF <credapp>-CustomerId IS INITIAL.
        APPEND VALUE #( %tky = <credapp>-%tky ) TO failed-creditapplication.
        APPEND VALUE #( %tky              = <credapp>-%tky
                        %state_area       = state_area-customer
                        %msg              = new_message( id       = 'ZIK_CREDAPP'
                                                         number   = '003'
                                                         severity = if_abap_behv_message=>severity-error )
                        %element-CustomerId = if_abap_behv=>mk-on ) TO reported-creditapplication.
      ELSEIF NOT line_exists( customers[ CustomerId = <credapp>-CustomerId ] ).
        APPEND VALUE #( %tky = <credapp>-%tky ) TO failed-creditapplication.
        APPEND VALUE #( %tky              = <credapp>-%tky
                        %state_area       = state_area-customer
                        %msg              = new_message( id       = 'ZIK_CREDAPP'
                                                         number   = '004'
                                                         severity = if_abap_behv_message=>severity-error
                                                         v1       = <credapp>-CustomerId )
                        %element-CustomerId = if_abap_behv=>mk-on ) TO reported-creditapplication.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD validateAmount.

    READ ENTITIES OF zik_i_credapp IN LOCAL MODE
      ENTITY CreditApplication
        FIELDS ( ProductId Amount CurrencyCode )
        WITH CORRESPONDING #( keys )
      RESULT DATA(credapps).

    LOOP AT credapps ASSIGNING FIELD-SYMBOL(<ca>).
      APPEND VALUE #( %tky        = <ca>-%tky
                      %state_area = state_area-amount ) TO reported-creditapplication.
    ENDLOOP.

    DATA(credprod) = credapps.
    DELETE credprod WHERE ProductId IS INITIAL.
    IF credprod IS INITIAL.
      RETURN.
    ENDIF.

    SELECT ProductId, MinAmount, MaxAmount, CurrencyCode
      FROM zik_i_product WITH PRIVILEGED ACCESS
      FOR ALL ENTRIES IN @credprod
      WHERE ProductId = @credprod-ProductId
      INTO TABLE @DATA(products).

    SELECT from_currency, to_currency, rate
      FROM zik_a_fxrate WITH PRIVILEGED ACCESS
      INTO TABLE @DATA(rates).

    DATA amount_in_product_ccy TYPE zik_a_credapp-amount.

    LOOP AT credapps ASSIGNING FIELD-SYMBOL(<credapp>).

      READ TABLE products ASSIGNING FIELD-SYMBOL(<product>)
           WITH KEY ProductId = <credapp>-ProductId.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      IF <credapp>-CurrencyCode = <product>-CurrencyCode.
        amount_in_product_ccy = <credapp>-Amount.
      ELSE.
        DATA(rate) = VALUE #( rates[ from_currency = <credapp>-CurrencyCode
                                     to_currency   = <product>-CurrencyCode ]-rate OPTIONAL ).
        IF rate IS INITIAL.
          APPEND VALUE #( %tky = <credapp>-%tky ) TO failed-creditapplication.
          APPEND VALUE #( %tky                  = <credapp>-%tky
                          %state_area           = state_area-amount
                          %msg                  = new_message( id       = 'ZIK_CREDAPP'
                                                               number   = '009'
                                                               severity = if_abap_behv_message=>severity-error
                                                               v1       = <credapp>-CurrencyCode
                                                               v2       = <product>-CurrencyCode )
                          %element-CurrencyCode = if_abap_behv=>mk-on ) TO reported-creditapplication.
          CONTINUE.
        ENDIF.
        amount_in_product_ccy = <credapp>-Amount * rate.
      ENDIF.

      IF amount_in_product_ccy < <product>-MinAmount
      OR amount_in_product_ccy > <product>-MaxAmount.
        APPEND VALUE #( %tky = <credapp>-%tky ) TO failed-creditapplication.
        APPEND VALUE #( %tky            = <credapp>-%tky
                        %state_area     = state_area-amount
                        %msg            = new_message( id       = 'ZIK_CREDAPP'
                                                       number   = '005'
                                                       severity = if_abap_behv_message=>severity-error
                                                       v1       = |{ amount_in_product_ccy }|
                                                       v2       = |{ <product>-MinAmount }|
                                                       v3       = |{ <product>-MaxAmount }|
                                                       v4       = <product>-CurrencyCode )
                        %element-Amount = if_abap_behv=>mk-on ) TO reported-creditapplication.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD validateTerm.

    READ ENTITIES OF zik_i_credapp IN LOCAL MODE
      ENTITY CreditApplication
        FIELDS ( ProductId TermMonths )
        WITH CORRESPONDING #( keys )
      RESULT DATA(credapps).

    LOOP AT credapps ASSIGNING FIELD-SYMBOL(<ca>).
      APPEND VALUE #( %tky        = <ca>-%tky
                      %state_area = state_area-term ) TO reported-creditapplication.
    ENDLOOP.

    DATA(credprod) = credapps.
    DELETE credprod WHERE ProductId IS INITIAL.
    IF credprod IS INITIAL.
      RETURN.
    ENDIF.

    SELECT ProductId, MinTermMonths, MaxTermMonths
      FROM zik_i_product WITH PRIVILEGED ACCESS
      FOR ALL ENTRIES IN @credprod
      WHERE ProductId = @credprod-ProductId
      INTO TABLE @DATA(products).

    LOOP AT credapps ASSIGNING FIELD-SYMBOL(<credapp>).

      READ TABLE products ASSIGNING FIELD-SYMBOL(<product>)
           WITH KEY ProductId = <credapp>-ProductId.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      IF <credapp>-TermMonths < <product>-MinTermMonths
      OR <credapp>-TermMonths > <product>-MaxTermMonths.
        APPEND VALUE #( %tky = <credapp>-%tky ) TO failed-creditapplication.
        APPEND VALUE #( %tky                = <credapp>-%tky
                        %state_area         = state_area-term
                        %msg                = new_message( id       = 'ZIK_CREDAPP'
                                                           number   = '006'
                                                           severity = if_abap_behv_message=>severity-error
                                                           v1       = |{ CONV i( <credapp>-TermMonths ) }|
                                                           v2       = |{ CONV i( <product>-MinTermMonths ) }|
                                                           v3       = |{ CONV i( <product>-MaxTermMonths ) }| )
                        %element-TermMonths = if_abap_behv=>mk-on ) TO reported-creditapplication.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD validateDTI.

    READ ENTITIES OF zik_i_credapp IN LOCAL MODE
      ENTITY CreditApplication
        FIELDS ( MonthlyPayment TotalIncome )
        WITH CORRESPONDING #( keys )
      RESULT DATA(credapps).

    LOOP AT credapps ASSIGNING FIELD-SYMBOL(<ca>).
      APPEND VALUE #( %tky        = <ca>-%tky
                      %state_area = state_area-dti ) TO reported-creditapplication.
    ENDLOOP.

    LOOP AT credapps ASSIGNING FIELD-SYMBOL(<credapp>).

      IF <credapp>-TotalIncome <= 0.
        APPEND VALUE #( %tky = <credapp>-%tky ) TO failed-creditapplication.
        APPEND VALUE #( %tky        = <credapp>-%tky
                        %state_area = state_area-dti
                        %msg        = new_message( id       = 'ZIK_CREDAPP'
                                                   number   = '008'
                                                   severity = if_abap_behv_message=>severity-error ) )
               TO reported-creditapplication.
        CONTINUE.
      ENDIF.

      DATA(ratio) = CONV decfloat34( <credapp>-MonthlyPayment ) / <credapp>-TotalIncome * 100.

      IF ratio > dti_limit_percent.
        APPEND VALUE #( %tky = <credapp>-%tky ) TO failed-creditapplication.
        APPEND VALUE #( %tky        = <credapp>-%tky
                        %state_area = state_area-dti
                        %msg        = new_message( id       = 'ZIK_CREDAPP'
                                                   number   = '007'
                                                   severity = if_abap_behv_message=>severity-error
                                                   v1       = |{ CONV i( ratio ) }|
                                                   v2       = |{ dti_limit_percent }| ) )
               TO reported-creditapplication.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD Submit.

    READ ENTITIES OF zik_i_credapp IN LOCAL MODE
      ENTITY CreditApplication
        FIELDS ( Status )
        WITH CORRESPONDING #( keys )
      RESULT DATA(credapps).

    DATA(submittable) = credapps.
    DELETE submittable WHERE Status <> status-draft.

    IF submittable IS NOT INITIAL.

      MODIFY ENTITIES OF zik_i_credapp IN LOCAL MODE
        ENTITY CreditApplication
          UPDATE FIELDS ( Status SubmittedAt )
          WITH VALUE #( FOR ca IN submittable ( %tky        = ca-%tky
                                                Status      = status-submitted
                                                SubmittedAt = utclong_current( ) ) )
        REPORTED DATA(update_reported).

      reported = CORRESPONDING #( DEEP update_reported ).

      READ ENTITIES OF zik_i_credapp IN LOCAL MODE
        ENTITY CreditApplication
          ALL FIELDS
          WITH CORRESPONDING #( submittable )
        RESULT DATA(submitted).

      result = VALUE #( FOR ca IN submitted ( %tky   = ca-%tky
                                              %param = ca ) ).
    ENDIF.

    LOOP AT credapps ASSIGNING FIELD-SYMBOL(<credapp>)
        WHERE Status <> status-draft.
      APPEND VALUE #( %tky = <credapp>-%tky ) TO failed-creditapplication.
      APPEND VALUE #( %tky = <credapp>-%tky
                      %msg = new_message( id       = 'ZIK_CREDAPP'
                                          number   = '010'
                                          severity = if_abap_behv_message=>severity-error
                                          v1       = |{ CONV i( <credapp>-ApplicationId ) }|
                                          v2       = <credapp>-Status ) )
             TO reported-creditapplication.
    ENDLOOP.

  ENDMETHOD.

  METHOD Approve.

    decide( EXPORTING keys       = CORRESPONDING #( keys )
                      new_status = status-approved
            IMPORTING result     = DATA(decided)
            CHANGING  failed     = failed
                      reported   = reported ).

    result = CORRESPONDING #( decided ).

  ENDMETHOD.

  METHOD Reject.

    decide( EXPORTING keys       = CORRESPONDING #( keys )
                      new_status = status-rejected
            IMPORTING result     = DATA(decided)
            CHANGING  failed     = failed
                      reported   = reported ).

    result = CORRESPONDING #( decided ).

  ENDMETHOD.

  METHOD decide.

    READ ENTITIES OF zik_i_credapp IN LOCAL MODE
      ENTITY CreditApplication
        FIELDS ( Status )
        WITH CORRESPONDING #( keys )
      RESULT DATA(credapps).

    DATA(decidable) = credapps.
    DELETE decidable WHERE Status <> status-submitted.

    IF decidable IS NOT INITIAL.

      MODIFY ENTITIES OF zik_i_credapp IN LOCAL MODE
        ENTITY CreditApplication
          UPDATE FIELDS ( Status DecidedAt DecidedBy )
          WITH VALUE #( FOR ca IN decidable
                        ( %tky      = ca-%tky
                          Status    = new_status
                          DecidedAt = utclong_current( )
                          DecidedBy = cl_abap_context_info=>get_user_technical_name( ) ) )
        REPORTED DATA(update_reported).

      reported-creditapplication = VALUE #( BASE reported-creditapplication
                                            ( LINES OF update_reported-creditapplication ) ).

      READ ENTITIES OF zik_i_credapp IN LOCAL MODE
        ENTITY CreditApplication
          ALL FIELDS
          WITH CORRESPONDING #( decidable )
        RESULT DATA(decided_apps).

      result = VALUE #( FOR ca IN decided_apps ( %tky   = ca-%tky
                                                 %param = ca ) ).
    ENDIF.

    LOOP AT credapps ASSIGNING FIELD-SYMBOL(<credapp>)
        WHERE Status <> status-submitted.
      APPEND VALUE #( %tky = <credapp>-%tky ) TO failed-creditapplication.
      APPEND VALUE #( %tky = <credapp>-%tky
                      %msg = new_message( id       = 'ZIK_CREDAPP'
                                          number   = '010'
                                          severity = if_abap_behv_message=>severity-error
                                          v1       = |{ CONV i( <credapp>-ApplicationId ) }|
                                          v2       = <credapp>-Status ) )
             TO reported-creditapplication.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_instance_authorizations.

    READ ENTITIES OF zik_i_credapp IN LOCAL MODE
      ENTITY CreditApplication
        FIELDS ( CreatedBy )
        WITH CORRESPONDING #( keys )
      RESULT DATA(credapps).

    DATA(current_user) = cl_abap_context_info=>get_user_technical_name( ).

    DATA(update_requested)  = xsdbool( requested_authorizations-%update         = if_abap_behv=>mk-on ).
    DATA(delete_requested)  = xsdbool( requested_authorizations-%delete         = if_abap_behv=>mk-on ).
    DATA(approve_requested) = xsdbool( requested_authorizations-%action-Approve = if_abap_behv=>mk-on ).
    DATA(reject_requested)  = xsdbool( requested_authorizations-%action-Reject  = if_abap_behv=>mk-on ).

    LOOP AT credapps INTO DATA(credapp).

      DATA(is_owner) = xsdbool( credapp-CreatedBy = current_user ).

      APPEND VALUE #( %tky = credapp-%tky ) TO result ASSIGNING FIELD-SYMBOL(<auth>).

      IF update_requested = abap_true.
        <auth>-%update = COND #( WHEN is_owner = abap_true
                                 THEN if_abap_behv=>auth-allowed
                                 ELSE if_abap_behv=>auth-unauthorized ).
      ENDIF.

      IF delete_requested = abap_true.
        <auth>-%delete = COND #( WHEN is_owner = abap_true
                                 THEN if_abap_behv=>auth-allowed
                                 ELSE if_abap_behv=>auth-unauthorized ).
      ENDIF.

      IF approve_requested = abap_true.
        <auth>-%action-Approve = COND #( WHEN is_owner = abap_true
                                         THEN if_abap_behv=>auth-unauthorized
                                         ELSE if_abap_behv=>auth-allowed ).
      ENDIF.

      IF reject_requested = abap_true.
        <auth>-%action-Reject = COND #( WHEN is_owner = abap_true
                                        THEN if_abap_behv=>auth-unauthorized
                                        ELSE if_abap_behv=>auth-allowed ).
      ENDIF.

    ENDLOOP.

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

      LOOP AT incomes USING KEY entity ASSIGNING FIELD-SYMBOL(<incomes>)
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

