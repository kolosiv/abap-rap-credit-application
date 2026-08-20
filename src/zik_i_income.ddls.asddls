@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Income source interface view'
define view entity ZIK_I_INCOME
  as select from zik_a_income
  association to parent ZIK_I_CREDAPP as _Application on $projection.ApplicationId = _Application.ApplicationId
  association [0..1] to ZIK_I_INCTYPE_VH as _IncomeType on $projection.IncomeType = _IncomeType.IncomeType
{
  key application_id        as ApplicationId,
  key income_id             as IncomeId,
      @EndUserText.label: 'Income Type'
      income_type           as IncomeType,
      @EndUserText.label: 'Monthly Amount'
      @Semantics.amount.currencyCode: 'CurrencyCode'
      monthly_amount        as MonthlyAmount,
      @EndUserText.label: 'Currency'
      currency_code         as CurrencyCode,
      @EndUserText.label: 'Documented'
      is_documented         as IsDocumented,
      @EndUserText.label: 'Employer'
      employer_name         as EmployerName,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      _Application,
      _IncomeType
}
