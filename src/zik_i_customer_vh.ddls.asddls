@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Customer value help'
@Search.searchable: true
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZIK_I_CUSTOMER_VH
  as select from ZIK_I_CUSTOMER
{
      @Search.defaultSearchElement: true
      @ObjectModel.text.element: ['FullName']
      @UI.textArrangement: #TEXT_LAST
      @UI.lineItem: [{ position: 10, importance: #HIGH }]
  key CustomerId,

      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      @UI.lineItem: [{ position: 20, importance: #HIGH }]
      LastName,

      @Search.defaultSearchElement: true
      @UI.lineItem: [{ position: 30, importance: #HIGH }]
      FirstName,

      @UI.lineItem: [{ position: 40, importance: #MEDIUM }]
      BirthDate,

      @Semantics.text: true
      @UI.hidden: true
      concat_with_space(LastName, FirstName, 1) as FullName
}
