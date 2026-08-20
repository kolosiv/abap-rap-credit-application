CLASS zik_cl_credapp_calc DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_sadl_exit_calc_element_read.

  PRIVATE SECTION.
    CONSTANTS: BEGIN OF status,
                 draft     TYPE zik_a_credapp-status VALUE 'DR',
                 submitted TYPE zik_a_credapp-status VALUE 'SU',
                 approved  TYPE zik_a_credapp-status VALUE 'AP',
                 rejected  TYPE zik_a_credapp-status VALUE 'RJ',
               END OF status.
ENDCLASS.


CLASS zik_cl_credapp_calc IMPLEMENTATION.

  METHOD if_sadl_exit_calc_element_read~get_calculation_info.

    LOOP AT it_requested_calc_elements INTO DATA(element).
      CASE to_upper( element ).
        WHEN 'TOTALCOST'.
          INSERT `MONTHLYPAYMENT` INTO TABLE et_requested_orig_elements.
          INSERT `TERMMONTHS`     INTO TABLE et_requested_orig_elements.
        WHEN 'OVERPAYMENT'.
          INSERT `MONTHLYPAYMENT` INTO TABLE et_requested_orig_elements.
          INSERT `TERMMONTHS`     INTO TABLE et_requested_orig_elements.
          INSERT `AMOUNT`         INTO TABLE et_requested_orig_elements.
        WHEN 'STATUSTEXT' OR 'STATUSCRITICALITY'.
          INSERT `STATUS`         INTO TABLE et_requested_orig_elements.
      ENDCASE.
    ENDLOOP.

  ENDMETHOD.

  METHOD if_sadl_exit_calc_element_read~calculate.

    DATA original TYPE STANDARD TABLE OF zik_i_credapp WITH EMPTY KEY.

    original = CORRESPONDING #( it_original_data ).

    LOOP AT original ASSIGNING FIELD-SYMBOL(<orig>).

      ASSIGN ct_calculated_data[ sy-tabix ] TO FIELD-SYMBOL(<calc>).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      DATA(total_cost) = CONV decfloat34( <orig>-MonthlyPayment ) * <orig>-TermMonths.

      ASSIGN COMPONENT 'TOTALCOST' OF STRUCTURE <calc> TO FIELD-SYMBOL(<total_cost>).
      IF sy-subrc = 0.
        <total_cost> = total_cost.
      ENDIF.

      ASSIGN COMPONENT 'OVERPAYMENT' OF STRUCTURE <calc> TO FIELD-SYMBOL(<overpayment>).
      IF sy-subrc = 0.
        <overpayment> = total_cost - <orig>-Amount.
      ENDIF.

      ASSIGN COMPONENT 'STATUSTEXT' OF STRUCTURE <calc> TO FIELD-SYMBOL(<status_text>).
      IF sy-subrc = 0.
        <status_text> = SWITCH string( <orig>-Status
                                       WHEN status-draft     THEN 'Draft'
                                       WHEN status-submitted THEN 'Submitted'
                                       WHEN status-approved  THEN 'Approved'
                                       WHEN status-rejected  THEN 'Rejected'
                                       ELSE `` ).
      ENDIF.

      ASSIGN COMPONENT 'STATUSCRITICALITY' OF STRUCTURE <calc> TO FIELD-SYMBOL(<criticality>).
      IF sy-subrc = 0.
        <criticality> = SWITCH i( <orig>-Status
                                  WHEN status-approved  THEN 3
                                  WHEN status-rejected  THEN 1
                                  WHEN status-submitted THEN 2
                                  ELSE 0 ).
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

