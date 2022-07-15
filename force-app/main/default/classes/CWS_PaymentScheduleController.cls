/* Component Name   : CWS_PaymentScheduleController 
 * Description      : This page is used to display Payment Schedule table in the OrderForm Quote Template
 * Created By       : Karthikeyan Sounderrajan
 * Created On       : 05/03/2020
 * Modification Log:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer                Date                            Modification ID              Description 
 * ---------------------------------------------------------------------------------------------------------------------------------------
 * Indra Ganesan          25-06-2020                       BED-8177 & BED-9263           Modified version
 * Indra Ganesan          30-07-2020                       BED-12795                     Minimum Commit Ramp &  Usage Based Ramp
 */
Public class CWS_PaymentScheduleController {
    Public List <PaymentScheduleWrapper> paymentScheduleList {
        get;
        set;
    }
    public Boolean showSchedule {
        get;
        set;
    }
    Public String currencySymbol {
        get;
        set;
    }
    public Integer minCommitProductsCount {
        get;
        set;
    }
	
	public integer actualTerm = 0;
	public integer spreadTerm = 0;
	
    public CWS_PaymentScheduleController() {
        Id quoteId = ApexPages.currentPage().getParameters().get('qid').escapeHtml4();
        String quoteType = '';
        if (quoteId != null) {
            List<SBQQ__Quote__c> quoteList = [Select Id, Name, CurrencyIsoCode, CWS_Currency_Symbol__c, CWS_Quote_Type__c,CWS_Actual_Contract_Term__c from SBQQ__Quote__c where id =: quoteId LIMIT 1];
            currencySymbol = quoteList[0].CWS_Currency_Symbol__c;
            minCommitProductsCount = 0;
            quoteType = quoteList[0].CWS_Quote_Type__c;
			//14086593 - Showing the spread plus 1 month in payment schedule
            actualTerm = integer.valueof(quoteList[0].CWS_Actual_Contract_Term__c);
            paymentScheduleList = getPaymentScheduleWrapperList(quoteId, quoteType);
            showSchedule = paymentScheduleList.size()> 0 ? true : false;
        }
    }

    public List <PaymentScheduleWrapper> getPaymentScheduleWrapperList(Id quoteId, String qType) {
        paymentScheduleList = new List <PaymentScheduleWrapper> ();
        Map <String, Integer> mapBillingTermValue = new Map <String, Integer> {
            CWS_ConstantClass.BillingTerm_Quarterly => 3,
            CWS_ConstantClass.BillingTerm_BiAnnual => 6,
            CWS_ConstantClass.BillingTerm_TriAnnual => 36,
            CWS_ConstantClass.BillingTerm_Annual => 12,
            CWS_ConstantClass.BillingTerm_Monthly => 1,
            CWS_ConstantClass.BillingTerm_OneTime => 1
        };
        List <QuoteLineWrapper> quoteLineWrapperList = new List <QuoteLineWrapper> ();
        Decimal totalOneTimePrice = 0;
        Integer totalMonths = 0;
        Set <Integer> UsrRmpQtySet = new Set <Integer> ();
        try {
            if (quoteId != null && qType != CWS_ConstantClass.QUOTE_TYPE_AMEND) {
                for (SBQQ__QuoteLine__c quoteLine: [Select Id, Name, CWS_Uneven_Spread_Values__c, CWS_Uneven_Spread__c, CWS_NetPrice__c,
                        SBQQ__SubscriptionTerm__c, SBQQ__BillingType__c,
                        SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__SubscriptionTerm__c,
                        SBQQ__Product__c, SBQQ__Product__r.CWS_ChargeType__c, SBQQ__Product__r.SBQQ__SubscriptionPricing__c,
                        CWS_Payment_Schedule_Driver__c, CWS_Period_for_Ramp_Spread_Deferment__c, CWS_FirstMonthAmountforSpread__c,
                        CWS_Billing_Term__c, CWS_ChargeType__c, SBQQ__SubscriptionPricing__c, SBQQ__NetTotal__c,
                        CWS_Reseller_Net_Price__c, CWS_Reseller_Net_Total__c, CWS_Min_Commit__c, CWS_Usage_Ramp_Qty__c, SBQQ__CustomerTotal__c,
                        SBQQ__Quote__r.CWS_Route_to_Market__c, SBQQ__Quote__r.CWS_Bill_To_Account__c,
                        SBQQ__Quote__r.CWS_Bill_To_Account__r.CWS_Distributor_Logic_Exclusion__c,
                        SBQQ__Quote__r.CWS_Partner_Signature_Received__c,SBQQ__Quote__r.SBQQ__Opportunity2__c,
                        SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Disti_Deal_Phase__c
                        from SBQQ__QuoteLine__c where (SBQQ__Product__r.CWS_Hide_on_OrderForm__c =: false OR SBQQ__Product__r.SBQQ__Hidden__c=: false) AND SBQQ__Quote__c =: quoteId LIMIT 2000
                    ]) {
                    if (quoteLine.SBQQ__Product__c != null && quoteLine.SBQQ__SubscriptionTerm__c != 0 && quoteLine.SBQQ__Quote__c != null &&
                        quoteLine.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c != 0) {

                        QuoteLineWrapper qlWrapper = new QuoteLineWrapper();
						qlWrapper.monthlyPrice=0;

                        if (quoteLine.CWS_Min_Commit__c == true) {
                            minCommitProductsCount = minCommitProductsCount + 1;
                        }

                        //charge type
                        if (quoteLine.CWS_ChargeType__c != null) {
                            qlWrapper.chargeType = quoteLine.CWS_ChargeType__c;
                        } else if ((quoteLine.CWS_ChargeType__c == null && quoteLine.SBQQ__Product__r.CWS_ChargeType__c != null)) {
                            qlWrapper.chargeType = quoteLine.SBQQ__Product__r.CWS_ChargeType__c;
                        }
                        //netPrice
                        qlWrapper.netPrice = quoteLine.CWS_NetPrice__c != null ? quoteLine.CWS_NetPrice__c : 0;

                        //BillingTerm
                        qlWrapper.billingTerm = quoteLine.CWS_Billing_Term__c != null ? quoteLine.CWS_Billing_Term__c : null;

                        //Billing Type
                        if (quoteLine.SBQQ__BillingType__c != null) {
                            qlWrapper.billingType = quoteLine.SBQQ__BillingType__c;
                        }

                        //Arrear Term
                        if (qlWrapper.billingTerm != null && ((qlWrapper.chargeType == CWS_ConstantClass.ChargeType_Recurring &&
                                    qlWrapper.billingType == 'Arrears') ||
                                qlWrapper.chargeType == CWS_ConstantClass.ChargeType_Usage)) {
                            qlWrapper.arrearTerm = mapBillingTermValue.get(qlWrapper.billingTerm) - 1;
                        } else {
                            qlWrapper.arrearTerm = 0;
                        }

                        //Product Type
                        if (quoteLine.CWS_Payment_Schedule_Driver__c != null) {
                            qlWrapper.paymentDriver = quoteLine.CWS_Payment_Schedule_Driver__c;
                        }

                        //BED-8177
                        qlWrapper.unevenSpread = quoteLine.CWS_Uneven_Spread__c;
                        //BED-8177

                        //Net Total
                        if (quoteLine.SBQQ__Quote__r.CWS_Route_to_Market__c == CWS_ConstantClass.RTM_Value_Direct) {
                            qlWrapper.netTotal = quoteLine.SBQQ__NetTotal__c != null ? quoteLine.SBQQ__NetTotal__c : 0;
                        } else if (quoteLine.SBQQ__Quote__r.CWS_Route_to_Market__c == CWS_ConstantClass.RTM_Value_Channel) {
                            qlWrapper.netTotal = quoteLine.SBQQ__NetTotal__c != null ? quoteLine.SBQQ__NetTotal__c : 0;
                            if (quoteLine.SBQQ__Quote__r.CWS_Bill_To_Account__c != null &&
                                quoteLine.SBQQ__Quote__r.CWS_Bill_To_Account__r.CWS_Distributor_Logic_Exclusion__c == true &&
                                quoteLine.SBQQ__Quote__r.SBQQ__Opportunity2__c!=null && 
                                quoteLine.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Disti_Deal_Phase__c == System.Label.CWS_Disti_Deal_End_Customer_Pricing) {
                                qlWrapper.netTotal = quoteLine.SBQQ__CustomerTotal__c;
                            }
                        } else if (quoteLine.SBQQ__Quote__r.CWS_Route_to_Market__c == CWS_ConstantClass.RTM_Value_IIT) {
                            if (quoteLine.SBQQ__Quote__r.CWS_Bill_To_Account__r.CWS_Distributor_Logic_Exclusion__c == true &&
                            quoteLine.SBQQ__Quote__r.SBQQ__Opportunity2__c!=null && 
                            quoteLine.SBQQ__Quote__r.SBQQ__Opportunity2__r.CWS_Disti_Deal_Phase__c == System.Label.CWS_Disti_Deal_End_Customer_Pricing) {
                                qlWrapper.netTotal = quoteLine.SBQQ__CustomerTotal__c;
                            } else {
                                qlWrapper.netTotal = quoteLine.CWS_Reseller_Net_Total__c;
                            }
                        }

                        //Sub Term
                        if (quoteLine.SBQQ__SubscriptionTerm__c != null) {
                            qlWrapper.subTerm = (Integer) quoteLine.SBQQ__SubscriptionTerm__c;
                        } else if (quoteLine.SBQQ__Quote__c != null && quoteLine.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c != null) {
                            qlWrapper.subTerm = (Integer) quoteLine.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c;
                        }

                        //Period for ramp spread deferment
                        qlWrapper.period = (quoteLine.CWS_Payment_Schedule_Driver__c != null && quoteLine.CWS_Period_for_Ramp_Spread_Deferment__c != null) ?
                            (Integer) quoteLine.CWS_Period_for_Ramp_Spread_Deferment__c : 0;


                        //Monthly Price
                        //BED-9272: Changes for Min Commit Ramp and Usage Ramp
                        /*if(quoteLine.CWS_Min_Commit__c || (quoteLine.CWS_Min_Commit__c && 
                            (qlWrapper.paymentDriver==CWS_ConstantClass.PAYMENT_SCHEDULE_USAGE_BASED_RAMP || 
                            qlWrapper.paymentDriver==CWS_ConstantClass.PAYMENT_SCHEDULE_MIN_COMMIT_RAMP))){
                            qlWrapper.monthlyPrice= (qlWrapper.subTerm!=null)?
                                (qlWrapper.netTotal/qlWrapper.subTerm).setScale(2,System.RoundingMode.HALF_UP):0;
                        }*/
                        //BED-12975
                        if (quoteLine.CWS_Min_Commit__c) {
                            if ((qlWrapper.paymentDriver == '' || qlWrapper.paymentDriver == null) || (((qlWrapper.paymentDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_USAGE_BASED_RAMP) || (qlWrapper.paymentDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_MIN_COMMIT_RAMP)) && quoteLine.CWS_Usage_Ramp_Qty__c == null)) {
                                system.debug('***payement driver = ' + qlWrapper.paymentDriver);
                                qlWrapper.monthlyPrice = (qlWrapper.subTerm != null) ? (qlWrapper.netTotal / qlWrapper.subTerm).setScale(2, System.RoundingMode.HALF_UP) : 0;
                            } else {
                                if (quoteLine.CWS_Min_Commit__c && qlWrapper.paymentDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_MIN_COMMIT_RAMP && quoteLine.CWS_Usage_Ramp_Qty__c != null) {
                                    qlWrapper.usagerampqty = quoteLine.CWS_Usage_Ramp_Qty__c;
                                    List <String> lstRampValues = qlWrapper.usagerampqty.split(';');
                                    Integer i = 0;
                                    if (lstRampValues.size() != null) {
                                        qlWrapper.mapMonthsToRampValues = new map <Integer, Decimal> ();
                                        for (String val: lstRampValues) {
                                            i++;
                                            qlWrapper.mapMonthsToRampValues.put(i, Decimal.valueOf(val));
                                        }
                                    }
                                }
                            }
                        } else if (qlWrapper.paymentDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_SPREAD) {
                            //BED-8177-START                       
                            if (quoteLine.CWS_Uneven_Spread_Values__c != null && quoteLine.CWS_Uneven_Spread__c) {
                                List <String> lstSpreadValues = new List <String> ();
                                lstSpreadValues = quoteLine.CWS_Uneven_Spread_Values__c.split(';');
                                Integer i = 0;
                                if (lstSpreadValues.size() != null) {
                                    qlWrapper.mapMonthsToSpreadValues = new map <Integer, Decimal> ();
                                    for (String val: lstSpreadValues) {
                                        i++;
                                        qlWrapper.mapMonthsToSpreadValues.put(i, Decimal.valueOf(val));
                                        system.debug('***' + qlWrapper.mapMonthsToSpreadValues.size());
                                    }
                                }
                                // BED-8177
                            } else {
                                if (qlWrapper.period <= mapBillingTermValue.get(qlWrapper.billingTerm)) {
                                    qlWrapper.firstMonthPrice = qlWrapper.netTotal;
                                } else if (qlWrapper.period> mapBillingTermValue.get(qlWrapper.billingTerm)) {
                                    qlWrapper.firstMonthPrice = qlWrapper.netTotal -
                                        (((qlWrapper.netTotal / qlWrapper.period).setScale(2, System.RoundingMode.DOWN)) *
                                            (qlWrapper.period - mapBillingTermValue.get(qlWrapper.billingTerm))
                                        );
                                }
                            }
                            qlWrapper.monthlyPrice = (qlWrapper.period != null && qlWrapper.period != 0) ?
                                (qlWrapper.netTotal / qlWrapper.period).setScale(2, System.RoundingMode.DOWN) : 0;
                        } else if (qlWrapper.billingTerm == CWS_ConstantClass.ChargeType_OneTime) {
                            qlWrapper.monthlyPrice = qlWrapper.netTotal;
                        } else if (qlWrapper.paymentDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_RAMP ||
                            qlWrapper.paymentDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_DEFERMENT) {
                            qlWrapper.monthlyPrice = (qlWrapper.subTerm != null) ? (qlWrapper.netTotal / qlWrapper.subTerm) : 0;
                        } else if (qlWrapper.chargeType == CWS_ConstantClass.ChargeType_Recurring) {
                            qlWrapper.monthlyPrice = qlWrapper.subTerm != null ? (qlWrapper.netTotal / qlWrapper.subTerm) : 0;
                        }

                        //BED-9272: 
                        //Usage Ramp Qty
                        if (quoteLine.CWS_Min_Commit__c && qlWrapper.paymentDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_MIN_COMMIT_RAMP && quoteLine.CWS_Usage_Ramp_Qty__c != null) {
                            qlWrapper.usagerampqty = quoteLine.CWS_Usage_Ramp_Qty__c;
                            List <String> urqLst = qlWrapper.usagerampqty.split(';');
                            for (String s: urqLst) {
                                UsrRmpQtySet.add(integer.valueof(s));
                            }
                        }

                        //totalTerm value= maximum months price will be applicable in the payment schedule
                        // (considering the sub term and deferment/ramp period or spread)
                        if (qlWrapper.paymentDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_SPREAD) {
                            //Billing Type wont be considered for spread.
                            qlWrapper.totalTerm = qlWrapper.period != null ? qlWrapper.period : 0;
                        } else if (qlWrapper.chargeType == CWS_ConstantClass.Chargetype_Onetime) {
                            if (qlWrapper.paymentDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_RAMP ||
                                qlWrapper.paymentDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_DEFERMENT) {
                                qlWrapper.totalTerm = qlWrapper.period + 1;
                            } else {
                                qlWrapper.totalTerm = 1;
                            }
                        } else if (qlWrapper.paymentDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_RAMP ||
                            qlWrapper.paymentDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_DEFERMENT) {
                            qlWrapper.totalTerm = (qlWrapper.period != null ? qlWrapper.period : 0) + (qlWrapper.subTerm != null ? qlWrapper.subTerm : 0);
                            if ((qlWrapper.chargeType == 'Recurring' && qlWrapper.billingType == 'Arrears') ||
                                qlWrapper.chargeType == 'Usage') {
                                qlWrapper.totalTerm = qlWrapper.totalTerm + mapBillingTermValue.get(qlWrapper.billingTerm);
                            }
                        } else if (qlWrapper.chargeType == CWS_ConstantClass.ChargeType_Recurring ||
                            qlWrapper.chargeType == CWS_ConstantClass.ChargeType_Usage ||
                            qlWrapper.paymentDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_MIN_COMMIT_RAMP ||
                            qlWrapper.paymentDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_USAGE_BASED_RAMP) {
                            qlWrapper.totalTerm = qlWrapper.subTerm != null ? qlWrapper.subTerm : 0;
                            if ((qlWrapper.chargeType == CWS_ConstantClass.ChargeType_Recurring &&
                                    qlWrapper.billingType == 'Arrears') || qlWrapper.chargeType == CWS_ConstantClass.ChargeType_Usage) {
                                qlWrapper.totalTerm = qlWrapper.totalTerm + mapBillingTermValue.get(qlWrapper.billingTerm);
                            }
                        }

                        //totalMonths in PaymentSchedule List
                        if (qlWrapper.paymentDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_SPREAD) {
                            totalMonths = totalMonths <qlWrapper.period ? qlWrapper.period : totalMonths;
							spreadTerm = spreadTerm < qlWrapper.period ? qlWrapper.period : spreadTerm;
                        } else if (qlWrapper.chargeType == CWS_ConstantClass.ChargeType_OneTime ||
                            qlWrapper.chargeType == CWS_ConstantClass.ChargeType_Recurring ||
                            qlWrapper.chargeType == CWS_ConstantClass.ChargeType_Usage) {

                            if (quoteLine.CWS_Min_Commit__c && (qlWrapper.paymentDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_USAGE_BASED_RAMP ||
                                    qlWrapper.paymentDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_MIN_COMMIT_RAMP)) {

                                if (quoteLine.CWS_Min_Commit__c) {
                                    if (qlWrapper.paymentDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_USAGE_BASED_RAMP) {
                                        totalMonths = totalMonths <(qlWrapper.period + qlWrapper.arrearTerm + 1) ? (qlWrapper.period + qlWrapper.arrearTerm + 1) : totalMonths;
                                        //totalMonths=(totalMonths<(qlWrapper.arrearTerm+1)?qlWrapper.arrearTerm+1:totalMonths);   
                                    }
                                    if (qlWrapper.paymentDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_MIN_COMMIT_RAMP) {
                                        totalMonths = totalMonths <(qlWrapper.period + qlWrapper.arrearTerm + 1) ? (qlWrapper.period + qlWrapper.arrearTerm + 1) : totalMonths;
                                        //totalMonths=(totalMonths<(qlWrapper.arrearTerm+1)?qlWrapper.arrearTerm+1:totalMonths)+ qlWrapper.mapMonthsToRampValues.size();
                                    }

                                } else if (qlWrapper.chargeType == CWS_ConstantClass.ChargeType_OneTime) {
                                    totalMonths = totalMonths <(qlWrapper.period + 2) ? (qlWrapper.period + 2) : totalMonths;
                                } else if (qlWrapper.paymentDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_RAMP ||
                                    qlWrapper.paymentDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_DEFERMENT ||
                                    qlWrapper.paymentDriver == null) {
                                    totalMonths = totalMonths <(qlWrapper.period + qlWrapper.arrearTerm + 1) ? (qlWrapper.period + qlWrapper.arrearTerm + 1) : totalMonths;
                                }
                            } else if (qlWrapper.chargeType == CWS_ConstantClass.ChargeType_OneTime) {
                                totalMonths = totalMonths <(qlWrapper.period + 1) ?
                                    (qlWrapper.period + 1) : totalMonths;
                            } else if (qlWrapper.paymentDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_RAMP ||
                                qlWrapper.paymentDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_DEFERMENT ||
                                qlWrapper.paymentDriver == null) {
                                totalMonths = totalMonths <(qlWrapper.period + qlWrapper.arrearTerm + 1) ?
                                    (qlWrapper.period + qlWrapper.arrearTerm + 1) : totalMonths;
                            }
                        }

                        //totalOneTimePrice
                        if (qlWrapper.chargeType == CWS_ConstantClass.ChargeType_OneTime && qlWrapper.paymentDriver == null) {
                            totalOneTimePrice = totalOneTimePrice + qlWrapper.netTotal;
                        }

                        quoteLineWrapperList.add(qlWrapper);
                    }
                }
                if (!quoteLineWrapperList.isEmpty()) {
                    Decimal servicePrice = 0;
                    Decimal recurringPrice;
                    Decimal recurringMinSpend;
                    Integer month;
                    Integer billingMonth;
					
					//14086593 - Showing the spread plus 1 month in payment schedule
                    if(actualTerm != 0 && totalMonths < actualTerm && spreadTerm == totalMonths){
                        totalMonths = totalMonths + 1;
                    }
					
                    for (Integer i = 0; i <totalMonths; i++) {
                        month = i + 1;
                        PaymentScheduleWrapper paymentScheduleWrapper = new PaymentScheduleWrapper();
						paymentScheduleWrapper.name='Month '+month +(month==totalMonths? '+':'');
                        //servicePrice=(month==1)?totalOneTimePrice:0;
                       // paymentScheduleWrapper.name = 'Month ' + month;
                        recurringPrice = 0;
                        servicePrice = 0;
                        recurringMinSpend = 0;
                        for (QuoteLineWrapper qlWrapper: quoteLineWrapperList) {
                            //BED-8177-START
                            if (qlWrapper.billingTerm == CWS_ConstantClass.ChargeType_OneTime &&
                                qlWrapper.paymentDriver != CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_SPREAD) {
                                if (qlWrapper.paymentDriver == null && month == 1) {
                                    servicePrice += (qlWrapper.netTotal != null ? qlWrapper.netTotal : 0);
                                } else if ((qlWrapper.paymentDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_RAMP ||
                                        qlWrapper.paymentDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_DEFERMENT) &&
                                    qlWrapper.period == month - 1) {
                                    servicePrice += (qlWrapper.netTotal != null ? qlWrapper.netTotal : 0);
                                }
                            } else if (qlWrapper.paymentDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_SPREAD && month <= qlWrapper.period) {
                                //BED-8177 START
                                if (qlWrapper.unevenSpread) {
                                    system.debug('** Uneven spread  **' + qlWrapper.unevenSpread);
                                    if (qlWrapper.mapMonthsToSpreadValues != null) {
                                        system.debug('** qlWrapper.mapMonthsToSpreadValues  **' + qlWrapper.mapMonthsToSpreadValues.size());
                                        for (Integer num: qlWrapper.mapMonthsToSpreadValues.keyset()) {
                                            if (month == num)
                                                servicePrice = servicePrice + qlWrapper.mapMonthsToSpreadValues.get(num);
                                        }
                                        system.debug('**servicePrice**' + servicePrice);
                                    }
                                } else if (qlWrapper.firstMonthPrice != null && month == 1) {
                                    servicePrice = servicePrice + qlWrapper.firstMonthPrice;
                                } else {
                                    if (math.mod(month - 1, mapBillingTermValue.get(qlWrapper.billingTerm)) == 0 &&
                                        qlWrapper.period>= month + mapBillingTermValue.get(qlWrapper.billingTerm) - 1) {
                                        servicePrice = servicePrice + (qlWrapper.monthlyPrice * mapBillingTermValue.get(qlWrapper.billingTerm));
                                    } else if (math.mod(month - 1, mapBillingTermValue.get(qlWrapper.billingTerm)) == 0 &&
                                        qlWrapper.period <(month + mapBillingTermValue.get(qlWrapper.billingTerm) - 1)) {
                                        servicePrice = servicePrice +
                                            (qlWrapper.monthlyPrice * (qlWrapper.period - month + 1) / mapBillingTermValue.get(qlWrapper.billingTerm));
                                    }
                                    system.debug('**servicePrice is set to monthly **' + servicePrice);
                                }
                            } else if (((qlWrapper.paymentDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_RAMP ||
                                        qlWrapper.paymentDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_DEFERMENT ||
                                        qlWrapper.paymentDriver == null) &&
                                    month > (qlWrapper.period + qlWrapper.arrearTerm) && month <= qlWrapper.totalTerm)) {
                                //billing Month will be counted from the actual month a products billing starts to be applicable ( based on deferment/ramp)
                                billingMonth = month - (qlWrapper.period + qlWrapper.arrearTerm);
                                if (qlWrapper.billingTerm == CWS_ConstantClass.BillingTerm_Monthly) {
                                    recurringPrice = recurringPrice + qlWrapper.monthlyPrice;
                                } else if (qlWrapper.billingTerm == CWS_ConstantClass.BillingTerm_Quarterly) {
                                    if (math.mod((billingMonth - 1), 3) == 0 && qlWrapper.subTerm >= (billingMonth + 2)) {
                                        recurringPrice = recurringPrice + (qlWrapper.monthlyPrice * 3);
                                    } else if (math.mod((billingMonth - 1), 3) == 0 && qlWrapper.subTerm <(billingMonth + 2)) {
                                        recurringPrice = recurringPrice + (qlWrapper.monthlyPrice * ((qlWrapper.subTerm - month + 1) / 3)).setScale(2, System.RoundingMode.HALF_UP);
                                    }
                                } else if (qlWrapper.billingTerm == CWS_ConstantClass.BillingTerm_BiAnnual) {
                                    if (math.mod((billingMonth - 1), 6) == 0 && qlWrapper.subTerm>= (billingMonth + 5)) {
                                        recurringPrice = recurringPrice + (qlWrapper.monthlyPrice * 6);
                                    } else if (math.mod((billingMonth - 1), 6) == 0 && qlWrapper.subTerm <(billingMonth + 5)) {
                                        recurringPrice = recurringPrice + (qlWrapper.monthlyPrice * ((qlWrapper.subTerm - month + 1) / 6)).setScale(2, System.RoundingMode.HALF_UP);
                                    }
                                } else if (qlWrapper.billingTerm == CWS_ConstantClass.BillingTerm_TriAnnual) {
                                    if (math.mod((billingMonth - 1), 36) == 0 && qlWrapper.subTerm >= (billingMonth + 35)) {
                                        recurringPrice = recurringPrice + (qlWrapper.monthlyPrice * 36);
                                    } else if (math.mod((billingMonth - 1), 36) == 0 && qlWrapper.subTerm <(billingMonth + 35)) {
                                        recurringPrice = recurringPrice + (qlWrapper.monthlyPrice * ((qlWrapper.subTerm - month + 1) / 36)).setScale(2, System.RoundingMode.HALF_UP);
                                    }
                                } else if (qlWrapper.billingTerm == CWS_ConstantClass.BillingTerm_Annual) {
                                    if (math.mod((billingMonth - 1), 12) == 0 && qlWrapper.subTerm >= (billingMonth + 11)) {
                                        recurringPrice = recurringPrice + (qlWrapper.monthlyPrice * 12);
                                    } else if (math.mod((billingMonth - 1), 12) == 0 && qlWrapper.subTerm <(billingMonth + 11)) {
                                        recurringPrice = recurringPrice + (qlWrapper.monthlyPrice * ((qlWrapper.subTerm - month + 1) / 12)).setScale(2, System.RoundingMode.HALF_UP);
                                    }
                                } else if (qlWrapper.billingTerm == CWS_ConstantClass.BillingTerm_OneTime) {
                                    if (billingMonth == 1) {
                                        recurringPrice = recurringPrice + qlWrapper.netTotal;
                                    }
                                }
                            } else if ((qlWrapper.paymentDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_MIN_COMMIT_RAMP ||
                                    qlWrapper.paymentDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_USAGE_BASED_RAMP) && month <= qlWrapper.totalTerm &&
                                month > qlWrapper.arrearTerm) {
                                //only in case of ramp usage qty is specified
                                if (qlWrapper.mapMonthsToRampValues != null) {
                                    for (Integer num: qlWrapper.mapMonthsToRampValues.keyset()) {
                                        if (month == num) {
                                            recurringMinSpend = recurringMinSpend + (qlWrapper.mapMonthsToRampValues.get(num) * (qlWrapper.netPrice / qlWrapper.subTerm));
                                        }
                                    }
                                }
                                qlWrapper.monthlyPrice = (qlWrapper.subTerm != null) ? (qlWrapper.netTotal / qlWrapper.subTerm).setScale(2, System.RoundingMode.HALF_UP) : 0;
                                if (month> qlWrapper.period + qlWrapper.arrearTerm) {

                                    //billing Month will be counted from the actual month a products billing starts to be applicable ( based on deferment/ramp)                                    
                                    billingMonth = month - (qlWrapper.period + qlWrapper.arrearTerm);
                                    if (qlWrapper.billingTerm == CWS_ConstantClass.BillingTerm_Monthly) {
                                        recurringMinSpend = recurringMinSpend + qlWrapper.monthlyPrice;

                                    } else if (qlWrapper.billingTerm == CWS_ConstantClass.BillingTerm_Quarterly) {
                                        if (math.mod((billingMonth - 1), 3) == 0 && qlWrapper.subTerm>= (billingMonth + 2)) {
                                            recurringMinSpend = recurringMinSpend + (qlWrapper.monthlyPrice * 3);
                                        } else if (math.mod((billingMonth - 1), 3) == 0 && qlWrapper.subTerm <(billingMonth + 2)) {
                                            recurringMinSpend = recurringMinSpend + (qlWrapper.monthlyPrice * ((qlWrapper.subTerm - month + 1) / 3)).setScale(2, System.RoundingMode.HALF_UP);
                                        }
                                    } else if (qlWrapper.billingTerm == CWS_ConstantClass.BillingTerm_BiAnnual) {
                                        if (math.mod((billingMonth - 1), 6) == 0 && qlWrapper.subTerm>= (billingMonth + 5)) {
                                            recurringMinSpend = recurringMinSpend + (qlWrapper.monthlyPrice * 6);
                                        } else if (math.mod((billingMonth - 1), 6) == 0 && qlWrapper.subTerm <(billingMonth + 5)) {
                                            recurringMinSpend = recurringMinSpend + (qlWrapper.monthlyPrice * ((qlWrapper.subTerm - month + 1) / 6)).setScale(2, System.RoundingMode.HALF_UP);
                                        }
                                    } else if (qlWrapper.billingTerm == CWS_ConstantClass.BillingTerm_TriAnnual) {
                                        if (math.mod((billingMonth - 1), 4) == 0 && qlWrapper.subTerm>= (billingMonth + 3)) {
                                            recurringMinSpend = recurringMinSpend + (qlWrapper.monthlyPrice * 4);
                                        } else if (math.mod((billingMonth - 1), 4) == 0 && qlWrapper.subTerm <(billingMonth + 3)) {
                                            recurringMinSpend = recurringMinSpend + (qlWrapper.monthlyPrice * ((qlWrapper.subTerm - month + 1) / 4)).setScale(2, System.RoundingMode.HALF_UP);
                                        }
                                    } else if (qlWrapper.billingTerm == CWS_ConstantClass.BillingTerm_Annual) {
                                        if (math.mod((billingMonth - 1), 12) == 0 && qlWrapper.subTerm>= (billingMonth + 11)) {
                                            recurringMinSpend = recurringMinSpend + (qlWrapper.monthlyPrice * 12);
                                        } else if (math.mod((billingMonth - 1), 12) == 0 && qlWrapper.subTerm <(billingMonth + 11)) {
                                            recurringMinSpend = recurringMinSpend + (qlWrapper.monthlyPrice * ((qlWrapper.subTerm - month + 1) / 12)).setScale(2, System.RoundingMode.HALF_UP);
                                        }
                                    } /*else if (qlWrapper.billingTerm == CWS_ConstantClass.BillingTerm_OneTime) {
                                        if (billingMonth == 1) {
                                            recurringMinSpend = recurringMinSpend + qlWrapper.netTotal;
                                        }
                                    }*/
                                }
                            }
                        }
                        paymentScheduleWrapper.servicePrice = servicePrice;
                        paymentScheduleWrapper.recurringPrice = recurringPrice;
                        paymentScheduleWrapper.recurringMinSpend = recurringMinSpend;
                        paymentScheduleWrapper.totalPrice = servicePrice + recurringPrice + recurringMinSpend;
                        if (math.mod(month, 2) == 0) {
                            paymentScheduleWrapper.bgColor = '#EFEFEF';
                        } else {
                            paymentScheduleWrapper.bgColor = 'white';
                        }
                        paymentScheduleList.add(paymentScheduleWrapper);
                    }
                }
            }
        } catch (Exception e) {
            System.debug(e.getMessage() + ' ' + e.getLineNumber());
        }
        return paymentScheduleList;
    }

    Public class QuoteLineWrapper {
        public String paymentDriver {
            get;
            set;
        }
        public String chargeType {
            get;
            set;
        }
        public Integer period {
            get;
            set;
        }
        public Integer subTerm {
            get;
            set;
        }
        public Integer totalTerm {
            get;
            set;
        }
        public String billingTerm {
            get;
            set;
        }
        public Decimal netTotal {
            get;
            set;
        }
        public Decimal netPrice {
            get;
            set;
        }
        public Decimal monthlyPrice {
            get;
            set;
        }
        public Decimal firstMonthPrice {
            get;
            set;
        }
        public Boolean unevenSpread {
            get;
            set;
        }
        public Map <Integer, Decimal> mapMonthsToSpreadValues {
            get;
            set;
        }
        public Map <Integer, Decimal> mapMonthsToRampValues {
            get;
            set;
        }
        public String usagerampqty {
            get;
            set;
        }
        public String billingType {
            get;
            set;
        }
        public Integer arrearTerm {
            get;
            set;
        }
    }

    Public class PaymentScheduleWrapper {
        public String name {
            get;
            set;
        }
        public Decimal servicePrice {
            get;
            set;
        }
        public Decimal recurringPrice {
            get;
            set;
        }
        //BED-9272
        public Decimal recurringMinSpend {
            get;
            set;
        }
        public Decimal totalPrice {
            get;
            set;
        }
        public String bgColor {
            get;
            set;
        }
    }
}