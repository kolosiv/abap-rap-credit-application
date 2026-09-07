CLASS zik_cl_fx_job DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_apj_dt_exec_object.
    INTERFACES if_apj_rt_exec_object.
ENDCLASS.


CLASS zik_cl_fx_job IMPLEMENTATION.

  METHOD if_apj_dt_exec_object~get_parameters.
    CLEAR: et_parameter_def,
           et_parameter_val.
  ENDMETHOD.

  METHOD if_apj_rt_exec_object~execute.

    DATA(outcome) = NEW zik_cl_fx_loader( )->load_rates( ).

    IF outcome-success = abap_true.
      RETURN.
    ENDIF.

    DATA(error) = NEW cx_apj_rt_content(
      textid = VALUE #( msgid = 'ZIK_CREDAPP'
                        msgno = '011'
                        attr1 = 'IF_T100_DYN_MSG~MSGV1' ) ).

    error->if_t100_dyn_msg~msgty = 'E'.
    error->if_t100_dyn_msg~msgv1 = outcome-message.

    RAISE EXCEPTION error.

  ENDMETHOD.

ENDCLASS.

