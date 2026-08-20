@EndUserText.label: 'Credit Application projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['ApplicationId']
define root view entity ZIK_C_CREDAPP
  provider contract transactional_query
  as projection on ZIK_I_CREDAPP
{
      @Search.defaultSearchElement: true
  key ApplicationId,

      @Search.defaultSearchElement: true
      @ObjectModel.text.element: ['CustomerName']
      @UI.textArrangement: #TEXT_LAST
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZIK_I_CUSTOMER_VH', element: 'CustomerId' },
                                           useForValidation: true }]
      CustomerId,

      @UI.hidden: true
      @Semantics.text: true
      _Customer.LastName as CustomerName,

      @Search.defaultSearchElement: true
      @ObjectModel.text.element: ['ProductName']
      @UI.textArrangement: #TEXT_LAST
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZIK_I_PRODUCT_VH', element: 'ProductId' },
                                           useForValidation: true }]
      ProductId,

      @UI.hidden: true
      @Semantics.text: true
      _Product.Description as ProductName,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      Amount,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CurrencyStdVH', element: 'Currency' },
                                           useForValidation: true }]
      CurrencyCode,

      TermMonths,
      InterestRate,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      MonthlyPayment,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      TotalIncome,

      @ObjectModel.text.element: ['StatusText']
      @UI.textArrangement: #TEXT_ONLY
      Status,

      SubmittedAt,
      DecidedAt,
      DecidedBy,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt,

      @EndUserText.label: 'Total Loan Cost'
      @Semantics.amount.currencyCode: 'CurrencyCode'
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZIK_CL_CREDAPP_CALC'
      virtual TotalCost         : abap.dec(15,2),

      @EndUserText.label: 'Overpayment'
      @Semantics.amount.currencyCode: 'CurrencyCode'
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZIK_CL_CREDAPP_CALC'
      virtual Overpayment       : abap.dec(15,2),

      @EndUserText.label: 'Status'
      @UI.hidden: true
      @Semantics.text: true
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZIK_CL_CREDAPP_CALC'
      virtual StatusText        : abap.char(10),

      @UI.hidden: true
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZIK_CL_CREDAPP_CALC'
      virtual StatusCriticality : abap.int1,

      _Income : redirected to composition child ZIK_C_INCOME
}
