@EndUserText.label: 'Credit Application projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define root view entity ZIK_C_CREDAPP
  provider contract transactional_query
  as projection on ZIK_I_CREDAPP
{
  key ApplicationId,
      CustomerId,
      ProductId,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      Amount,
      CurrencyCode,
      TermMonths,
      InterestRate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      MonthlyPayment,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      TotalIncome,
      Status,
      SubmittedAt,
      DecidedAt,
      DecidedBy,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt,
      _Income : redirected to composition child ZIK_C_INCOME
}
