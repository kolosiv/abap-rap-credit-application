@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Credit Application interface view'
define root view entity ZIK_I_CREDAPP
  as select from zik_a_credapp
  composition [0..*] of ZIK_I_INCOME as _Income
  association [0..1] to ZIK_I_CUSTOMER as _Customer on $projection.CustomerId = _Customer.CustomerId
  association [0..1] to ZIK_I_PRODUCT  as _Product  on $projection.ProductId  = _Product.ProductId
{
      @EndUserText.label: 'Application ID'
  key application_id        as ApplicationId,
      @EndUserText.label: 'Customer'
      customer_id           as CustomerId,
      @EndUserText.label: 'Product'
      product_id            as ProductId,
      @EndUserText.label: 'Loan Amount'
      @Semantics.amount.currencyCode: 'CurrencyCode'
      amount                as Amount,
      @EndUserText.label: 'Currency'
      currency_code         as CurrencyCode,
      @EndUserText.label: 'Term in Months'
      term_months           as TermMonths,
      @EndUserText.label: 'Interest Rate'
      interest_rate         as InterestRate,
      @EndUserText.label: 'Monthly Payment'
      @Semantics.amount.currencyCode: 'CurrencyCode'
      monthly_payment       as MonthlyPayment,
      @EndUserText.label: 'Total Income'
      @Semantics.amount.currencyCode: 'CurrencyCode'
      total_income          as TotalIncome,
      @EndUserText.label: 'Status'
      status                as Status,
      @EndUserText.label: 'Submitted At'
      submitted_at          as SubmittedAt,
      @EndUserText.label: 'Decided At'
      decided_at            as DecidedAt,
      @EndUserText.label: 'Decided By'
      decided_by            as DecidedBy,
      @Semantics.user.createdBy: true
      created_by            as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,
      @Semantics.user.localInstanceLastChangedBy: true
      last_changed_by       as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      _Income,
      _Customer,
      _Product
}
