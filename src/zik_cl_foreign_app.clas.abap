CLASS zik_cl_foreign_app DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
  PRIVATE SECTION.
    CONSTANTS c_app_id TYPE zik_a_credapp-application_id VALUE '0000009999'.
    CONSTANTS c_owner  TYPE abp_creation_user VALUE 'OTHERUSER'.
ENDCLASS.

CLASS zik_cl_foreign_app IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.

    DELETE FROM zik_a_income  WHERE application_id = @c_app_id.
    DELETE FROM zik_a_credapp WHERE application_id = @c_app_id.

    DATA now TYPE timestampl.
    GET TIME STAMP FIELD now.

    DATA app TYPE zik_a_credapp.
    app = VALUE #( application_id        = c_app_id
                   customer_id           = '00000003'
                   product_id            = 'CONSUMER'
                   amount                = '20000.00'
                   currency_code         = 'EUR'
                   term_months           = '024'
                   interest_rate         = '15.900'
                   monthly_payment       = '978.31'
                   total_income          = '3000.00'
                   status                = 'SU'
                   submitted_at          = utclong_current( )
                   created_by            = c_owner
                   created_at            = now
                   last_changed_by       = c_owner
                   last_changed_at       = now
                   local_last_changed_at = now ).
    INSERT zik_a_credapp FROM @app.

    DATA inc TYPE zik_a_income.
    inc = VALUE #( application_id        = c_app_id
                   income_id             = '0010'
                   income_type           = 'SA'
                   monthly_amount        = '3000.00'
                   currency_code         = 'EUR'
                   employer_name         = 'Other Corp'
                   local_last_changed_at = now ).
    INSERT zik_a_income FROM @inc.

    out->write( |Application { c_app_id } seeded, CreatedBy = { c_owner }, status SU| ).

  ENDMETHOD.
ENDCLASS.
