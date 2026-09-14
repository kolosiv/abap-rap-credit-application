CLASS ltc_credapp DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES tt_credapp_db     TYPE STANDARD TABLE OF zik_a_credapp WITH EMPTY KEY.
    TYPES tt_app_keys       TYPE TABLE FOR READ IMPORT zik_i_credapp.
    TYPES ts_reported_late  TYPE RESPONSE FOR REPORTED LATE zik_i_credapp.
    TYPES ts_reported_early TYPE RESPONSE FOR REPORTED EARLY zik_i_credapp.

    CLASS-DATA class_under_test     TYPE REF TO lhc_credapp.
    CLASS-DATA cds_test_environment TYPE REF TO if_cds_test_environment.

    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.

    METHODS setup.
    METHODS teardown.

    METHODS given_application
      IMPORTING status        TYPE zik_a_credapp-status
                payment       TYPE zik_a_credapp-monthly_payment DEFAULT 0
                income        TYPE zik_a_credapp-total_income    DEFAULT 0
      RETURNING VALUE(keys)   TYPE tt_app_keys.

    METHODS messages_in_late
      IMPORTING reported     TYPE ts_reported_late
      RETURNING VALUE(count) TYPE i.

    METHODS messages_in_early
      IMPORTING reported     TYPE ts_reported_early
      RETURNING VALUE(count) TYPE i.

    METHODS validate_dti_within_limit FOR TESTING.
    METHODS validate_dti_exceeded     FOR TESTING.
    METHODS validate_dti_no_income    FOR TESTING.

    METHODS features_draft            FOR TESTING.
    METHODS features_submitted        FOR TESTING.

    METHODS submit_from_draft         FOR TESTING.
    METHODS submit_wrong_status       FOR TESTING.
ENDCLASS.


CLASS ltc_credapp IMPLEMENTATION.

  METHOD class_setup.
    CREATE OBJECT class_under_test FOR TESTING.
    cds_test_environment = cl_cds_test_environment=>create( i_for_entity = 'ZIK_I_CREDAPP' ).
  ENDMETHOD.

  METHOD setup.
    cds_test_environment->clear_doubles( ).
  ENDMETHOD.

  METHOD teardown.
    ROLLBACK ENTITIES.
  ENDMETHOD.

  METHOD class_teardown.
    cds_test_environment->destroy( ).
  ENDMETHOD.


  METHOD given_application.

    DATA(mocked) = VALUE tt_credapp_db(
                     ( application_id  = '0000000001'
                       customer_id     = '00000001'
                       product_id      = 'CONSUMER'
                       amount          = '10000.00'
                       currency_code   = 'EUR'
                       term_months     = '060'
                       interest_rate   = '9.500'
                       monthly_payment = payment
                       total_income    = income
                       status          = status ) ).

    cds_test_environment->insert_test_data( mocked ).

    keys = VALUE #( FOR m IN mocked ( ApplicationId = m-application_id ) ).

  ENDMETHOD.

  METHOD messages_in_late.
    LOOP AT reported-creditapplication INTO DATA(line) WHERE %msg IS BOUND.
      count += 1.
    ENDLOOP.
  ENDMETHOD.

  METHOD messages_in_early.
    LOOP AT reported-creditapplication INTO DATA(line) WHERE %msg IS BOUND.
      count += 1.
    ENDLOOP.
  ENDMETHOD.


  METHOD validate_dti_within_limit.

    DATA(keys) = given_application( status  = 'DR'
                                    payment = '1000.00'
                                    income  = '5000.00' ).

    DATA failed   TYPE RESPONSE FOR FAILED LATE   zik_i_credapp.
    DATA reported TYPE RESPONSE FOR REPORTED LATE zik_i_credapp.

    class_under_test->validatedti(
      EXPORTING keys     = CORRESPONDING #( keys )
      CHANGING  failed   = failed
                reported = reported ).

    cl_abap_unit_assert=>assert_initial(
      msg = 'DTI 20 percent must not fail'
      act = failed ).

    cl_abap_unit_assert=>assert_equals(
      msg = 'the state_area clearing line must be present'
      exp = 1
      act = lines( reported-creditapplication ) ).

    cl_abap_unit_assert=>assert_equals(
      msg = 'no message expected'
      exp = 0
      act = messages_in_late( reported ) ).

  ENDMETHOD.


  METHOD validate_dti_exceeded.

    DATA(keys) = given_application( status  = 'DR'
                                    payment = '3000.00'
                                    income  = '5000.00' ).

    DATA failed   TYPE RESPONSE FOR FAILED LATE   zik_i_credapp.
    DATA reported TYPE RESPONSE FOR REPORTED LATE zik_i_credapp.

    class_under_test->validatedti(
      EXPORTING keys     = CORRESPONDING #( keys )
      CHANGING  failed   = failed
                reported = reported ).

    cl_abap_unit_assert=>assert_equals(
      msg = 'DTI 60 percent must fail the instance'
      exp = 1
      act = lines( failed-creditapplication ) ).

    cl_abap_unit_assert=>assert_equals(
      msg = 'exactly one message expected'
      exp = 1
      act = messages_in_late( reported ) ).

  ENDMETHOD.


  METHOD validate_dti_no_income.

    DATA(keys) = given_application( status  = 'DR'
                                    payment = '1000.00'
                                    income  = 0 ).

    DATA failed   TYPE RESPONSE FOR FAILED LATE   zik_i_credapp.
    DATA reported TYPE RESPONSE FOR REPORTED LATE zik_i_credapp.

    class_under_test->validatedti(
      EXPORTING keys     = CORRESPONDING #( keys )
      CHANGING  failed   = failed
                reported = reported ).

    cl_abap_unit_assert=>assert_equals(
      msg = 'application without income must fail'
      exp = 1
      act = lines( failed-creditapplication ) ).

    cl_abap_unit_assert=>assert_equals(
      msg = 'exactly one message expected'
      exp = 1
      act = messages_in_late( reported ) ).

  ENDMETHOD.


  METHOD features_draft.

    DATA(keys) = given_application( status = 'DR' ).

    DATA result   TYPE TABLE FOR INSTANCE FEATURES RESULT zik_i_credapp\\CreditApplication.
    DATA failed   TYPE RESPONSE FOR FAILED EARLY   zik_i_credapp.
    DATA reported TYPE RESPONSE FOR REPORTED EARLY zik_i_credapp.

    class_under_test->get_instance_features(
      EXPORTING keys               = CORRESPONDING #( keys )
                requested_features = VALUE #( %action-Submit  = if_abap_behv=>mk-on
                                              %action-Approve = if_abap_behv=>mk-on
                                              %action-Reject  = if_abap_behv=>mk-on
                                              %action-Edit    = if_abap_behv=>mk-on
                                              %update         = if_abap_behv=>mk-on
                                              %delete         = if_abap_behv=>mk-on )
      CHANGING  result             = result
                failed             = failed
                reported           = reported ).

    cl_abap_unit_assert=>assert_equals( msg = 'one result line expected'
                                        exp = 1
                                        act = lines( result ) ).

    cl_abap_unit_assert=>assert_equals( msg = 'update enabled in DR'
                                        exp = if_abap_behv=>fc-o-enabled
                                        act = result[ 1 ]-%features-%update ).

    cl_abap_unit_assert=>assert_equals( msg = 'delete enabled in DR'
                                        exp = if_abap_behv=>fc-o-enabled
                                        act = result[ 1 ]-%features-%delete ).

    cl_abap_unit_assert=>assert_equals( msg = 'Submit enabled in DR'
                                        exp = if_abap_behv=>fc-o-enabled
                                        act = result[ 1 ]-%action-Submit ).

    cl_abap_unit_assert=>assert_equals( msg = 'Approve disabled in DR'
                                        exp = if_abap_behv=>fc-o-disabled
                                        act = result[ 1 ]-%action-Approve ).

    cl_abap_unit_assert=>assert_equals( msg = 'Reject disabled in DR'
                                        exp = if_abap_behv=>fc-o-disabled
                                        act = result[ 1 ]-%action-Reject ).

  ENDMETHOD.


  METHOD features_submitted.

    DATA(keys) = given_application( status = 'SU' ).

    DATA result   TYPE TABLE FOR INSTANCE FEATURES RESULT zik_i_credapp\\CreditApplication.
    DATA failed   TYPE RESPONSE FOR FAILED EARLY   zik_i_credapp.
    DATA reported TYPE RESPONSE FOR REPORTED EARLY zik_i_credapp.

    class_under_test->get_instance_features(
      EXPORTING keys               = CORRESPONDING #( keys )
                requested_features = VALUE #( %action-Submit  = if_abap_behv=>mk-on
                                              %action-Approve = if_abap_behv=>mk-on
                                              %action-Reject  = if_abap_behv=>mk-on
                                              %action-Edit    = if_abap_behv=>mk-on
                                              %update         = if_abap_behv=>mk-on
                                              %delete         = if_abap_behv=>mk-on )
      CHANGING  result             = result
                failed             = failed
                reported           = reported ).

    cl_abap_unit_assert=>assert_equals( msg = 'one result line expected'
                                        exp = 1
                                        act = lines( result ) ).

    cl_abap_unit_assert=>assert_equals( msg = 'submitted application is frozen for update'
                                        exp = if_abap_behv=>fc-o-disabled
                                        act = result[ 1 ]-%features-%update ).

    cl_abap_unit_assert=>assert_equals( msg = 'Edit disabled in SU'
                                        exp = if_abap_behv=>fc-o-disabled
                                        act = result[ 1 ]-%action-Edit ).

    cl_abap_unit_assert=>assert_equals( msg = 'Submit disabled in SU'
                                        exp = if_abap_behv=>fc-o-disabled
                                        act = result[ 1 ]-%action-Submit ).

    cl_abap_unit_assert=>assert_equals( msg = 'Approve enabled in SU'
                                        exp = if_abap_behv=>fc-o-enabled
                                        act = result[ 1 ]-%action-Approve ).

    cl_abap_unit_assert=>assert_equals( msg = 'Reject enabled in SU'
                                        exp = if_abap_behv=>fc-o-enabled
                                        act = result[ 1 ]-%action-Reject ).

  ENDMETHOD.


  METHOD submit_from_draft.

    DATA(keys) = given_application( status  = 'DR'
                                    payment = '1000.00'
                                    income  = '5000.00' ).

    DATA result   TYPE TABLE FOR ACTION RESULT zik_i_credapp~Submit.
    DATA mapped   TYPE RESPONSE FOR MAPPED EARLY   zik_i_credapp.
    DATA failed   TYPE RESPONSE FOR FAILED EARLY   zik_i_credapp.
    DATA reported TYPE RESPONSE FOR REPORTED EARLY zik_i_credapp.

    class_under_test->submit(
      EXPORTING keys     = CORRESPONDING #( keys )
      CHANGING  result   = result
                mapped   = mapped
                failed   = failed
                reported = reported ).

    cl_abap_unit_assert=>assert_initial( msg = 'submit from DR must not fail'
                                         act = failed ).

    cl_abap_unit_assert=>assert_equals( msg = 'one result line expected'
                                        exp = 1
                                        act = lines( result ) ).

    cl_abap_unit_assert=>assert_equals( msg = 'action result carries the new status'
                                        exp = 'SU'
                                        act = result[ 1 ]-%param-Status ).

    cl_abap_unit_assert=>assert_not_initial( msg = 'SubmittedAt must be stamped'
                                             act = result[ 1 ]-%param-SubmittedAt ).

    READ ENTITY zik_i_credapp
      FIELDS ( Status ) WITH CORRESPONDING #( keys )
      RESULT DATA(after).

    cl_abap_unit_assert=>assert_equals( msg = 'buffer holds the new status'
                                        exp = 'SU'
                                        act = after[ 1 ]-Status ).

  ENDMETHOD.


  METHOD submit_wrong_status.

    DATA(keys) = given_application( status  = 'AP'
                                    payment = '1000.00'
                                    income  = '5000.00' ).

    DATA result   TYPE TABLE FOR ACTION RESULT zik_i_credapp~Submit.
    DATA mapped   TYPE RESPONSE FOR MAPPED EARLY   zik_i_credapp.
    DATA failed   TYPE RESPONSE FOR FAILED EARLY   zik_i_credapp.
    DATA reported TYPE RESPONSE FOR REPORTED EARLY zik_i_credapp.

    class_under_test->submit(
      EXPORTING keys     = CORRESPONDING #( keys )
      CHANGING  result   = result
                mapped   = mapped
                failed   = failed
                reported = reported ).

    cl_abap_unit_assert=>assert_equals( msg = 'submit from AP must be refused'
                                        exp = 1
                                        act = lines( failed-creditapplication ) ).

    cl_abap_unit_assert=>assert_equals( msg = 'refusal must be explained by a message'
                                        exp = 1
                                        act = messages_in_early( reported ) ).

    cl_abap_unit_assert=>assert_initial( msg = 'no result for a refused action'
                                         act = result ).

    READ ENTITY zik_i_credapp
      FIELDS ( Status ) WITH CORRESPONDING #( keys )
      RESULT DATA(after).

    cl_abap_unit_assert=>assert_equals( msg = 'status must stay untouched'
                                        exp = 'AP'
                                        act = after[ 1 ]-Status ).

  ENDMETHOD.

ENDCLASS.

