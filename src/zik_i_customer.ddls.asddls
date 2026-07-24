@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Customer interface view'
define view entity ZIK_I_CUSTOMER
  as select from zik_a_customer
{
      @EndUserText.label: 'Customer ID'
  key customer_id as CustomerId,
      @EndUserText.label: 'First Name'
      first_name  as FirstName,
      @EndUserText.label: 'Last Name'
      last_name   as LastName,
      @EndUserText.label: 'Date of Birth'
      birth_date  as BirthDate
}
