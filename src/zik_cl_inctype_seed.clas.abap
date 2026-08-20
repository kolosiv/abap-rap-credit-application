CLASS zik_cl_inctype_seed DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.


CLASS zik_cl_inctype_seed IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    DATA types TYPE STANDARD TABLE OF zik_a_inctype WITH EMPTY KEY.

    types = VALUE #( ( income_type = 'SA' description = 'Salary' )
                     ( income_type = 'RE' description = 'Rental income' )
                     ( income_type = 'BU' description = 'Business income' ) ).

    DELETE FROM zik_a_inctype.
    INSERT zik_a_inctype FROM TABLE @types.

    out->write( |{ sy-dbcnt } income types loaded| ).

  ENDMETHOD.

ENDCLASS.

