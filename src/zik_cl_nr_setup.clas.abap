CLASS zik_cl_nr_setup DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
  PRIVATE SECTION.
    CONSTANTS c_object TYPE cl_numberrange_intervals=>nr_object VALUE 'ZIK_CRDAPP'.
    CONSTANTS c_range  TYPE c LENGTH 2 VALUE '01'.
ENDCLASS.

CLASS zik_cl_nr_setup IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.

    " ---- 1. Interval 01 (rerun-safe: catch and show) ----
    TRY.
        cl_numberrange_intervals=>create(
          EXPORTING
            object   = c_object
            interval = VALUE #( ( nrrangenr  = c_range
                                  fromnumber = '1'
                                  tonumber   = '9999999999'
                                  procind    = 'I' ) )
          IMPORTING
            error   = DATA(lv_error)
            warning = DATA(lv_warning) ).
        COMMIT WORK AND WAIT.
        out->write( |Interval created. error={ lv_error } warning={ lv_warning }| ).
      CATCH cx_number_ranges INTO DATA(lx_iv).
        out->write( |Interval create skipped/failed: { lx_iv->get_text( ) }| ).
    ENDTRY.

    " ---- 2. Read numbers ----
    TRY.
        DO 2 TIMES.
          cl_numberrange_runtime=>number_get(
            EXPORTING
              nr_range_nr       = c_range
              object            = c_object
              quantity          = 1
            IMPORTING
              number            = DATA(lv_number)
              returncode        = DATA(lv_rc)
              returned_quantity = DATA(lv_qty) ).
          out->write( |number_get #{ sy-index }: number={ lv_number } rc={ lv_rc } qty={ lv_qty }| ).
        ENDDO.

        cl_numberrange_runtime=>number_get(
          EXPORTING
            nr_range_nr       = c_range
            object            = c_object
            quantity          = 3
          IMPORTING
            number            = lv_number
            returncode        = lv_rc
            returned_quantity = lv_qty ).
        DATA lv_from TYPE int8.
        lv_from = lv_number - lv_qty + 1.
        out->write( |batch(3): top={ lv_number } rc={ lv_rc } qty={ lv_qty } -> range { lv_from }..{ lv_number }| ).

      CATCH cx_number_ranges INTO DATA(lx_get).
        out->write( |number_get failed: { lx_get->get_text( ) }| ).
    ENDTRY.

  ENDMETHOD.
ENDCLASS.
