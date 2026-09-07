@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Supported currency value help'
@Search.searchable: true
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZIK_I_CURRENCY_VH
  as select distinct from zik_a_fxrate
{
      @EndUserText.label: 'Currency'
      @Search.defaultSearchElement: true
      @UI.lineItem: [{ position: 10, importance: #HIGH }]
  key from_currency as Currency
}
