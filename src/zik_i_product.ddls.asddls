@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Credit product interface view'
define view entity ZIK_I_PRODUCT
  as select from zik_a_product
{
      @EndUserText.label: 'Product ID'
  key product_id      as ProductId,
      @EndUserText.label: 'Description'
      description     as Description,
      @EndUserText.label: 'Min Amount'
      @Semantics.amount.currencyCode: 'CurrencyCode'
      min_amount      as MinAmount,
      @EndUserText.label: 'Max Amount'
      @Semantics.amount.currencyCode: 'CurrencyCode'
      max_amount      as MaxAmount,
      @EndUserText.label: 'Currency'
      currency_code   as CurrencyCode,
      @EndUserText.label: 'Min Term (Months)'
      min_term_months as MinTermMonths,
      @EndUserText.label: 'Max Term (Months)'
      max_term_months as MaxTermMonths,
      @EndUserText.label: 'Interest Rate'
      interest_rate   as InterestRate
}
