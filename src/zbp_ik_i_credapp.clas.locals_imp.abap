CLASS lhc_credapp DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR CreditApplication
      RESULT result.

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

ENDCLASS.
