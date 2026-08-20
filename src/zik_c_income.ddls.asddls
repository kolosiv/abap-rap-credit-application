@EndUserText.label: 'Income projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity ZIK_C_INCOME
  as projection on ZIK_I_INCOME
{
  key ApplicationId,
  key IncomeId,

      @ObjectModel.text.element: ['IncomeTypeText']
      @UI.textArrangement: #TEXT_ONLY
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZIK_I_INCTYPE_VH', element: 'IncomeType' },
                                           useForValidation: true }]
      IncomeType,

      @UI.hidden: true
      @Semantics.text: true
      _IncomeType.Description as IncomeTypeText,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      MonthlyAmount,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CurrencyStdVH', element: 'Currency' },
                                           useForValidation: true }]
      CurrencyCode,

      IsDocumented,
      EmployerName,
      LocalLastChangedAt,
      _Application : redirected to parent ZIK_C_CREDAPP
}
