@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Income type value help'
@Search.searchable: true
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZIK_I_INCTYPE_VH
  as select from zik_a_inctype
{
      @EndUserText.label: 'Income Type'
      @Search.defaultSearchElement: true
      @ObjectModel.text.element: ['Description']
      @UI.textArrangement: #TEXT_ONLY
      @UI.lineItem: [{ position: 10, importance: #HIGH }]
  key income_type as IncomeType,

      @EndUserText.label: 'Description'
      @Search.defaultSearchElement: true
      @Semantics.text: true
      @UI.lineItem: [{ position: 20, importance: #HIGH }]
      description as Description
}
