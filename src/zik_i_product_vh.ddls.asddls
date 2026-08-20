@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Credit product value help'
@Search.searchable: true
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZIK_I_PRODUCT_VH
  as select from ZIK_I_PRODUCT
{
      @Search.defaultSearchElement: true
      @ObjectModel.text.element: ['Description']
      @UI.textArrangement: #TEXT_LAST
      @UI.lineItem: [{ position: 10, importance: #HIGH }]
  key ProductId,

      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      @Semantics.text: true
      @UI.lineItem: [{ position: 20, importance: #HIGH }]
      Description,

      @UI.lineItem: [{ position: 30, importance: #MEDIUM }]
      @Semantics.amount.currencyCode: 'CurrencyCode'
      MinAmount,

      @UI.lineItem: [{ position: 40, importance: #MEDIUM }]
      @Semantics.amount.currencyCode: 'CurrencyCode'
      MaxAmount,

      @UI.lineItem: [{ position: 50, importance: #MEDIUM }]
      CurrencyCode,

      @UI.lineItem: [{ position: 60, importance: #LOW }]
      MinTermMonths,

      @UI.lineItem: [{ position: 70, importance: #LOW }]
      MaxTermMonths,

      @UI.lineItem: [{ position: 80, importance: #HIGH }]
      InterestRate
}
