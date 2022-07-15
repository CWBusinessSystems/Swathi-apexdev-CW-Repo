/*Class Name: CWS_OrderItemTriggerHelper
*Description: Helper Class for CWS_OrderItemTriggerHandler
*Created By: swachatterjee
*Created On: 4/5/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*swachatterjee          4/13/2020           -                  Initial Version
*swachatterjee          4/13/2020        BED - 1287            beforeInsert() 
*swachattterjee         4/29/2020        BED - 6945            added logic for beforeUpdate method 
*Vaishnavi              5/20/2020        BED - 10930           added logic for price per billing frequency in before insert  
*Aditya                 6/25/2020        BED-  10706           added logic for Additional Restrictions
*Prashant               10/30/2020       MNG - 14034650        added logic afterInsert - Check the box Create_L_P_Case__c on Order when at least one of the Services Provisioned on OrderItem is Unchecked
*Mahak Bansal           9/8/2021         OBD-57                Updated logic to evaluate and populate uneven spread Value and Uneven spread type 
*/
public class CWS_OrderItemTriggerHelper {

    /**
    * @@Method: beforeInsert
    * @Developer: swachatterjee@deloitte.com
    * @Description: 
    * @Requirement/Issue: BED-1287, 6891, 6882, 6873
     */
    public static void beforeInsert (List<SObject> lstNewOrderItems){
        // Declarte the collections
        Map<Id,SBQQ__QuoteLine__c> mapQuoteLines = null;
        Map<Id,OrderItem> mapOrderItems = null;
        Map<Id,Order> mapOrders = null;
        Map<Id, SBQQ__Subscription__c> mapSubscription = null;
        Map<Id, Set<Id>> mapAccountSubscription = null;
        Map<Id, Product2> mapProducts = null;
        Set<Id> setQuotelineIds = null;
        Set<Id> setOrderItemIds = null;
        Set<Id> setOrderIds = null;
        Set<Id> setAccountIds = null;
        Set<Id> setProductIds = null;
       
        try{
            // Instantiate the Collections
            setQuotelineIds = new Set<Id>();
            setOrderItemIds = new Set<Id>();
            setOrderIds = new Set<Id>();
            mapQuoteLines = new Map<Id,SBQQ__QuoteLine__c>();
            mapOrders = new Map<Id,Order>();
            mapProducts = new Map<Id,Product2>();
            setAccountIds = new Set<Id>();
            setProductIds = new Set<Id>();
            
            //Iterate through the list of Order items in context
            for(SObject sObjInstance: lstNewOrderItems){
                OrderItem sObjOrderItem = (OrderItem)sObjInstance;
                setQuotelineIds.add(sObjOrderItem.SBQQ__QuoteLine__c);
                setOrderItemIds.add(sObjOrderItem.SBQQ__RevisedOrderProduct__c);
                setOrderIds.add(sObjOrderItem.OrderId);
                setProductIds.add(sObjOrderItem.Product2Id);
            }
            // Query the quotelines
            // Swagata note: This can be optimized: Remove this query and add twin fields
            if(!setQuotelineIds.isEmpty()){
                mapQuoteLines = new Map<Id,SBQQ__QuoteLine__c> ([select Id, CWS_NetTotal__c, CWS_Price_Per_Billing_Period__c,CWS_Uneven_Spread_Values__c,CWS_Renewed_Line__c,SBQQ__Existing__c, CWS_NetPrice__c,CWS_RegularPrice__c, SBQQ__ListPrice__c,SBQQ__EffectiveStartDate__c,SBQQ__EffectiveEndDate__c,SBQQ__Quote__r.CWS_Master__c, SBQQ__Quote__r.SBQQ__StartDate__c, SBQQ__ListTotal__c,SBQQ__NetTotal__c, SBQQ__RegularTotal__c,SBQQ__Quote__r.SBQQ__BillingFrequency__c,SBQQ__NetPrice__c,SBQQ__SubscriptionTerm__c,CWS_Payment_Schedule_Driver__c,CWS_Period_for_Ramp_Spread_Deferment__c,SBQQ__Product__r.CWS_ChargeType__c,SBQQ__Product__r.CWS_Implementation_Spread_Eligibility__c, SBQQ__Product__r.SBQQ__SubscriptionTerm__c,CWS_Billing_Term__c, CWS_Calculated_Subscription_Term__c from SBQQ__QuoteLine__c where Id in:setQuotelineIds LIMIT 20000]);
            }

            if(!setOrderItemIds.isEmpty()){
                mapOrders = new Map<Id,Order>([SELECT Id,AccountId,  CWS_Master__c, CWS_Quote_Type__c,CWS_OF_Signed_Date__c, CWS_Actual_Contract_Term__c from Order where Id in : setOrderIds LIMIT 10000]);
            }
            for(Order ord :mapOrders.values()){
                setAccountIds.add(ord.AccountId);
            }
            // Map Account with all the Subscriptions
            if(!setAccountIds.isEmpty()){
                mapSubscription = new Map<Id, SBQQ__Subscription__c>([select id, SBQQ__Product__c, SBQQ__Account__c from SBQQ__Subscription__c where SBQQ__Account__c in: setAccountIds]);
                mapAccountSubscription = new Map<Id, Set<Id>>();
                for(SBQQ__Subscription__c sub :mapSubscription.values()){
                    Id accId = sub.SBQQ__Account__c;
                    if(!mapAccountSubscription.containsKey(accId)){
                        mapAccountSubscription.put(accId, new Set<Id>());
                    }
                    mapAccountSubscription.get(accId).add(sub.SBQQ__Product__c);
                }

            }
            
            if(!setProductIds.isEmpty()){
                mapProducts = new Map<Id,Product2>([select id, name, SBQQ__PricingMethod__c, SBQQ__BlockPricingField__c, CWS_Charge_Model__c ,CWS_ProductCode__c, CWS_Additional_Restrictions__c from Product2 where id in: setProductIds]);
            }
            
            if(!setOrderItemIds.isEmpty()){
                mapOrderItems = new Map<Id,OrderItem> ([select Id,CWS_Calculated_Subscription_Term__c, CWS_ZuoraSubscriptionRatePlanId__c,CWS_Zuora_Subscription_RPC_Number__c,Order.CWS_OF_Signed_Date__c from OrderItem where Id in: setOrderItemIds LIMIT 10000]);
            }

            for(SObject sObjInstance: lstNewOrderItems){
                OrderItem sObjOrderItem = (OrderItem)sObjInstance;
                Order sObjOrder = mapOrders.get(sObjOrderItem.OrderId) ; 
                Product2 sObjProd = mapProducts.get(sObjOrderItem.Product2Id);
                String chargeModel = sObjProd.CWS_Charge_Model__c;
                String prodCode = sObjProd.CWS_ProductCode__c;
                String pricingMethod = sObjProd.SBQQ__PricingMethod__c;
                String pricingField = sObjProd.SBQQ__BlockPricingField__c;
                Decimal netPrice = null;
                Decimal quantity = null;
                //BED-10706 Start
                //Only New Business or Add-On Amendment Scenario
                //If additional Restriction is New Agreement or Conversion,provisional eligibility is Manual
                if(sObjOrder.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS || 
                                                (sObjOrder.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMEND 
                                                                        && sObjOrderItem.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_ADD_ON)){
                    //considering that no twin field is created for additional rest. on QuoteLine, will change if required
                    if( sObjProd.CWS_Additional_Restrictions__c == CWS_ConstantClass.Product_AdditionRestriction_NewAgreement){
                        //Check if Product is being purchased for the first time
                        if( mapAccountSubscription.size() == 0 || (mapAccountSubscription.size()>0 
                                                                        && !mapAccountSubscription.get(sObjOrder.AccountId).contains(sObjOrderItem.Product2Id))){
                            sObjOrderItem.CWS_Provisioning_Eligibility__c = CWS_ConstantClass.PROVISIONAL_ELIGIBILITY_MANUAL;
                        }
                    }
                          
                }//BED 10706 End
                
                
                // Capture the Quote line id 
                Id idQuoteLine = sObjOrderItem.SBQQ__QuoteLine__c;
                SBQQ__QuoteLine__c sObjQuoteLine = null;
                 Integer multiplicationFactor;
                // Validate if the quote line id is blank
                if(!String.isBlank(idQuoteLine) && mapQuoteLines.containsKey(idQuoteLine)){
                    sObjQuoteLine = mapQuoteLines.get(idQuoteLine);
                }
                // Populate the List, Regular and Net total fields
                sObjOrderItem.CWS_RegularTotal__c = sObjQuoteLine.SBQQ__RegularTotal__c <> null ? sObjQuoteLine.SBQQ__RegularTotal__c: 0.0d;
                sObjOrderItem.CWS_ListTotal__c = sObjQuoteLine.SBQQ__ListTotal__c <> null ? sObjQuoteLine.SBQQ__ListTotal__c: 0.0d;
                //BED-13713
                sObjOrderItem.UnitPrice = sObjQuoteLine.CWS_NetPrice__c <> null ? sObjQuoteLine.CWS_NetPrice__c: 0.0d;
                
                
                //BED-13371
                Boolean master = sObjOrder.CWS_Master__c;
                Boolean excludateFromNetTotal = sObjOrderItem.CWS_Exclude_from_Net_Total__c;
                 if(((master && excludateFromNetTotal)|| prodCode == CWS_ConstantClass.Minimum_Commit_Code) && sObjQuoteLine.CWS_RegularPrice__c != null ){
                    netPrice = sObjQuoteLine.CWS_RegularPrice__c;
                  
                 }else{
                    if(sObjQuoteLine.CWS_NetPrice__c != null){
                      netPrice = sObjQuoteLine.CWS_NetPrice__c;
                        
                    }
                 }           
                             
                 /**
                  * Calculate Price per billing period based on CWS_Billing Term and charge type
                  *Invoke the utility method to calculate PPBP
                  */ 
                 calcPricePerBillingPeriod( sObjOrderItem, sObjQuoteLine.CWS_Price_Per_Billing_Period__c, sObjQuoteLine.CWS_Billing_Term__c, sObjQuoteLine.SBQQ__Product__r.CWS_ChargeType__c , 
                                sObjOrderItem.CWS_Calculated_Subscription_Term__c, netPrice, sObjOrderItem.CWS_Regular_Unit_Price__c ,sObjQuoteLine.CWS_Payment_Schedule_Driver__c, sObjQuoteLine.CWS_Period_for_Ramp_Spread_Deferment__c, master, excludateFromNetTotal);
                         
                
                
                // Invoke the utility method to populate the provisioning dates
                populateProvisioningDates(true,false,sObjOrderItem,null,mapOrders,mapQuoteLines);
                Decimal netTotal; 
         
            
                String billcycle = sObjOrderItem.CWS_Bill_Cycle_Type__c;
                String psd = sObjOrderItem.CWS_Payment_Schedule_Driver__c;
                Decimal ppsd = sObjOrderItem.CWS_Period_for_Ramp_Spread_Deferment__c;
                String chargeType = sObjOrderItem.SBQQ__ChargeType__c;
                Date startDate = sObjOrderItem.ServiceDate;
                Decimal noOfDaysIn1stMonth = date.daysInMonth(startDate.year(),startDate.month());
                Decimal startDay = startDate.day();
                Date endDate;
                Date billingEndDate;
                String unevenValues =  sObjOrderItem.CWS_Uneven_Spread_Values__c;  
                Boolean unevenSpread = sObjOrderItem.CWS_Uneven_Spread__c;      
               if(psd== CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_SPREAD){
                 if(ppsd <> null && ppsd >0){
                    billingEndDate = (startDate.addMonths(Integer.valueOf(ppsd)));
                 }else{
                    billingEndDate = (startDate.addMonths(1));
                 }
               }else if(sObjQuoteLine.SBQQ__Product__r.CWS_Implementation_Spread_Eligibility__c && (String.isBlank(psd))){
                        billingEndDate = (startDate.addMonths(1));
               }else{
                     billingEndDate = sObjOrderItem.EndDate;
               }
            
            
                 if(psd!= null && psd == CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_SPREAD){
                    endDate = billingEndDate.addDays(-1); 
                    }else{
                         endDate = sObjOrderItem.EndDate; 
                         }
                         
                         
                Decimal noOfDaysInLastMonth = endDate<>null ? date.daysInMonth(endDate.year(),endDate.month()) : null;
                
                Decimal term = sObjQuoteLine.CWS_Calculated_Subscription_Term__c;
                Boolean isTermInteger; 
                    if(Integer.valueOf(term)==term){
                      isTermInteger = true;  
                    }else{
                        isTermInteger= false;
                    }  
                if(Test.isRunningTest()){
                    isTermInteger= false;
                }
                Boolean proRate;
                if(startDay <> 1 && (String.isBlank(billcycle) || billcycle == CWS_ConstantClass.BillCycleType)){
                   
                    if(chargeType != CWS_ConstantClass.ChargeType_OneTime || psd== CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_SPREAD){
                        proRate = true;
                    }else{
                        proRate = false;
                    }
                }else{
                    proRate = false;
                }
                
                //Check if Product has block pricing then take the quantity as 1 else original quantity
                if(pricingMethod == CWS_ConstantClass.PRICINGMETHOD_BLOCK && pricingField!=null){
                    quantity = 1;
                }else{
                    quantity = sObjOrderItem.SBQQ__OrderedQuantity__c;
                }
                
                //Invoke the utitlity method to populate proRateCalculation method
                if( String.isblank(unevenValues) && !unevenSpread && ((proRate && noOfDaysIn1stMonth<>noOfDaysInLastMonth) || !isTermInteger) && 
                    (chargeModel == CWS_ConstantClass.ChargeModel_perUnit || chargeModel == CWS_ConstantClass.ChargeModel_flatFee) && 
                        (sObjQuoteLine.SBQQ__Product__r.CWS_ChargeType__c == CWS_ConstantClass.ChargeType_Recurring || 
                                (sObjQuoteLine.CWS_Payment_Schedule_Driver__c == CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_SPREAD && sObjQuoteLine.SBQQ__Product__r.CWS_Implementation_Spread_Eligibility__c))){
                                    if(sObjOrderItem.CWS_Exclude_from_Net_Total__c){
                                        netTotal = sObjQuoteLine.SBQQ__RegularTotal__c;
                                    }else{
                                        netTotal = sObjQuoteLine.CWS_NetTotal__c;
                                    }
                        proRateCalculation(sObjOrderItem,sObjQuoteLine.CWS_Payment_Schedule_Driver__c, sObjOrderItem.CWS_Period_for_Ramp_Spread_Deferment__c, sObjOrderItem.ServiceDate, sObjOrderItem.EndDate, billingEndDate, sObjQuoteLine.CWS_Billing_Term__c, netTotal, sObjQuoteLine.CWS_Calculated_Subscription_Term__c, quantity, sObjOrderItem.CWS_Price_Per_Billing_Period__c);
                   }
                Id idRevisedOrderProduct = sObjOrderItem.SBQQ__RevisedOrderProduct__c;
                if(idRevisedOrderProduct<>null && mapOrderItems.containsKey(idRevisedOrderProduct)){
                    OrderItem sObjRevisedOrderItem = mapOrderItems.get(idRevisedOrderProduct);
                    sObjOrderItem.CWS_ZuoraSubscriptionRatePlanId__c =sObjRevisedOrderItem.CWS_ZuoraSubscriptionRatePlanId__c;
                    sObjOrderItem.CWS_Zuora_Subscription_RPC_Number__c = sObjRevisedOrderItem.CWS_Zuora_Subscription_RPC_Number__c;
                }

            }
        } catch (Exception e) {
            CWS_ExceptionHandler.logException(e, 'OrderItem' , 'CWS_OrderItemTriggerHelper','beforeInsert' ,'', null, null ,'Before Insert' , null);
        }
    }
    /**
    * @Method: afterInsert
    * @Developer: swachatterjee@deloitte.com
    * @Description: 
    * @Issue: BED-1287, 6945
    * @Developer: Prashant
    * @Issue: MNG - 14034650 (10/30/2020)
     */
    public static void afterInsert (Map<Id,SObject> mapNewOrderItems){
        // Declare local list of Orders for Update DML
        List<Order> lstOrdersToBeUpdated = null;
        List<OrderItem> lstOrderitemsUpdated =null;
        List<OrderItem> newOrderItems = mapNewOrderItems.values();
        // Declare Map for counting the number of NA and Manual Counts
        Map<Id,Integer> mapOrderLineCounts =null;
        Map<Id,Integer> mapOrderLineNACounts = null;
        Map<Id,Integer> mapOrderLineManualCounts = null;
        Map<Id,Integer> mapOrderLineImmediateCounts = null;
        Map<Id,Integer> mapOrderLineExistingCounts = null;
        Map<Id,String> mapOrderStatus =null;
        //Prashant: Declaring Map for updating Order's Create_L_P_Case__c
        Map<Id, Boolean> orderToUpdateMap = null;
        try{
            // Instantiate the collections
            mapOrderLineCounts = new Map<Id,Integer>();
            mapOrderLineNACounts = new Map<Id,Integer>();
            mapOrderLineManualCounts = new Map<Id,Integer>();
            mapOrderLineImmediateCounts = new Map<Id,Integer>();
            mapOrderLineExistingCounts = new Map<Id,Integer>();
            mapOrderStatus = new Map<Id,String>();
            
            //Prashant:
            orderToUpdateMap = new Map<Id, Boolean>();
                
            lstOrdersToBeUpdated = new List<Order>();
            lstOrderitemsUpdated = new List<OrderItem>();
            Integer noOfSpread = 0;
            Integer noOfUnevenSpread = 0;
            
            // Temporary Set of Ids for query
            Set<Id> setOrderIds = new Set<Id>();
            //Iterate through the list of Order items in Trigger context
            for(SObject sObjInstance: mapNewOrderItems.values()){
                OrderItem sObjOrderItem = (OrderItem)sObjInstance;
                // Create a variable to store the parent order id
                setOrderIds.add(sObjOrderItem.OrderId);
                if(sObjOrderItem.CWS_Payment_Schedule_Driver__c == CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_SPREAD){
                    //count the no. of Spread Lines
                    noOfSpread++;
                    if(sObjOrderItem.CWS_Uneven_Spread__c){
                        //COunt the no. of spread lines with uneven spread as true
                        noOfUnevenSpread++;
                    }
                }
                
                //Prashant: Check if CWS_ServicesProvisioned__c is unchecked
                if(!sObjOrderItem.CWS_ServicesProvisioned__c && sObjOrderItem.OrderId != null){
                    orderToUpdateMap.put(sObjOrderItem.OrderId, true);
                } 
            }   
           
            // Iterate through the persisted records to take overall counts
            // Applicable for only net new lines in any scenarios
            // Query the parent Orders with status
            map<Id,Date> mapOIServiceDate = new Map<Id,date>();
            map<Id, Id> mapOIOrder = new  Map<Id,Id>();
            if(!setOrderIds.isEmpty()){
                for(OrderItem sObjOrderItem: [select Id, CWS_NetTotal__c, CWS_Uneven_Spread_Values__c, CWS_Transaction_Type__c, Quantity, SBQQ__QuoteLine__r.CWS_Transaction_Type__c, SBQQ__QuoteLine__r.CWS_Uneven_Spread__c, CWS_Period_for_Ramp_Spread_Deferment__c,CWS_Uneven_Spread__c,SBQQ__QuoteLine__r.CWS_Renewed_Line__c,SBQQ__QuoteLine__r.SBQQ__Existing__c,SBQQ__QuoteLine__r.SBQQ__NetPrice__c, Order.Status,OrderId,CWS_Provisioning_Eligibility__c,CWS_Payment_Schedule_Driver__c,Order.CWS_Upfront_Billing_Date__c,Order.CWS_Upfront_Billing__c,ServiceDate from OrderItem where OrderId in:setOrderIds LIMIT 50000]){
                    // Store the Order Id in a temp variable
                    Id idOrder = sObjOrderItem.OrderId; 
                    Boolean isRenewed = sObjOrderItem.SBQQ__QuoteLine__r.CWS_Renewed_Line__c;
                    Boolean isExisting = sObjOrderItem.SBQQ__QuoteLine__r.SBQQ__Existing__c;
                    String transactionType = sObjOrderItem.CWS_Transaction_Type__c;
                    mapOrderStatus.put(idOrder, sObjOrderItem.Order.Status);
                    // Verify if the line is renewed or amended
                    if((isExisting || isRenewed) && (transactionType <> CWS_ConstantClass.TRANSACTION_TYPE_UPGRADE || sObjOrderItem.CWS_Provisioning_Eligibility__c <> CWS_ConstantClass.PROVISIONAL_ELIGIBILITY_MANUAL)) {
                        mapOrderLineExistingCounts = updateMapCounter(mapOrderLineExistingCounts, idOrder, 1);
                    }
                    // Manual
                    if(!isExisting && !isRenewed && sObjOrderItem.CWS_Provisioning_Eligibility__c==CWS_ConstantClass.PROVISIONAL_ELIGIBILITY_IMMEDIATE){
                        mapOrderLineImmediateCounts=updateMapCounter(mapOrderLineImmediateCounts,idOrder,1);
                    }
                    // Verify if the Provisioning Eligibility is NA
                    if(!isExisting && !isRenewed && sObjOrderItem.CWS_Provisioning_Eligibility__c==CWS_ConstantClass.PROVISIONAL_ELIGIBILITY_NA){
                        mapOrderLineNACounts=updateMapCounter(mapOrderLineNACounts,idOrder,1);
                    }
                    // Verify if the Provisioning Eligibility is Deferment
                    //14079401 Order status should be pending fulfillment for NB and Amendment Addon/Upgrade in case of Manual Products
                    if( (!isExisting  || transactionType == CWS_ConstantClass.TRANSACTION_TYPE_UPGRADE) && !isRenewed && sObjOrderItem.CWS_Provisioning_Eligibility__c==CWS_ConstantClass.PROVISIONAL_ELIGIBILITY_MANUAL
                        && sObjOrderItem.CWS_Payment_Schedule_Driver__c<>CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_DEFERMENT){
                        mapOrderLineManualCounts = updateMapCounter(mapOrderLineManualCounts, idOrder,1);
                    }else if(!isExisting && !isRenewed && sObjOrderItem.CWS_Provisioning_Eligibility__c==CWS_ConstantClass.PROVISIONAL_ELIGIBILITY_MANUAL
                        && sObjOrderItem.CWS_Payment_Schedule_Driver__c==CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_DEFERMENT){
                        mapOrderLineImmediateCounts = updateMapCounter(mapOrderLineImmediateCounts, idOrder,1);
                    }
                    mapOrderLineCounts = updateMapCounter(mapOrderLineCounts, idOrder,1);
                    
                    // BED-10788 Start: If there is atleast one uneven spread, all the other Spread lines will be marked as uneven
                    if(sObjOrderItem.CWS_Payment_Schedule_Driver__c<>null  && sObjOrderItem.CWS_Payment_Schedule_Driver__c == CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_SPREAD 
                                            && (noOfUnevenSpread>0 && noOfUnevenSpread != noOfSpread) && !sObjOrderItem.CWS_Uneven_Spread__c ){

                        decimal intRSDPeriod = sObjOrderItem.CWS_Period_for_Ramp_Spread_Deferment__c;
                        decimal netTotal = sObjOrderItem.SBQQ__QuoteLine__r.SBQQ__NetPrice__c;
                        decimal perPeriodValue = (netTotal/ intRSDPeriod);
                        String unevenValues = '';
                        for(integer x=0; x<intRSDPeriod; x++){
                            unevenValues = unevenValues + String.ValueOf(perPeriodValue) + ';';
                        }
                        
                        sObjOrderItem.CWS_Uneven_Spread_Values__c = unevenValues;
                        sObjOrderItem.CWS_Uneven_Spread__c = true;
                                                
                        //For uneven spread proration calculation is not valid
                        sObjOrderItem.CWS_Price_For_Last_Billing_Period__c = null;
                        sObjOrderItem.CWS_PriceAdjustmentDate__c = null;
                        //Order Items to be updated with Uneven spread values and unevenspread checkbox as true
                        lstOrderitemsUpdated.add(sObjOrderItem);
                    }//BED-10788 End
                    /*** 14130963 Starts ***/
                    if(sObjOrderItem.CWS_Payment_Schedule_Driver__c == CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_SPREAD 
                       && sObjOrderItem.SBQQ__QuoteLine__r.CWS_Uneven_Spread__c 
                       && sObjOrderItem.SBQQ__QuoteLine__r.CWS_Transaction_Type__c == 'New' 
                       && sObjOrderItem.Quantity > 1){
                        decimal netTotalOrderItemPerQuantity = sObjOrderItem.CWS_NetTotal__c/sObjOrderItem.Quantity;
                        Decimal roundedSpreadTotal = 0.00;
                        String unevenSpreadValString = '';
                        List<String> spreadValueList = sObjOrderItem.CWS_Uneven_Spread_Values__c.split(';');
                        for(Integer i=0; i < spreadValueList.size(); i++){
                            Decimal currentIterationSpreadValue = (Decimal.valueOf(spreadValueList[i])/sObjOrderItem.Quantity).setScale(2);
                            roundedSpreadTotal += currentIterationSpreadValue;
                            if(i == spreadValueList.size() && roundedSpreadTotal != netTotalOrderItemPerQuantity){
                                if(roundedSpreadTotal > netTotalOrderItemPerQuantity){
                                    Decimal adjustmentValue = roundedSpreadTotal - netTotalOrderItemPerQuantity;
                                    unevenSpreadValString += String.valueOf(currentIterationSpreadValue + adjustmentValue) + ';'; 
                                    break;
                                }
                                else if(roundedSpreadTotal < netTotalOrderItemPerQuantity){
                                    Decimal adjustmentValue = netTotalOrderItemPerQuantity - roundedSpreadTotal;
                                    unevenSpreadValString += String.valueOf(currentIterationSpreadValue - adjustmentValue) + ';'; 
                                    break;
                                }
                            }
                            unevenSpreadValString += String.valueOf(currentIterationSpreadValue) + ';'; 
                        }
                        if(unevenSpreadValString != ''){
                            sObjOrderItem.CWS_Uneven_Spread_Values__c = unevenSpreadValString;  
                            if(!lstOrderitemsUpdated.contains(sObjOrderItem)){
                                lstOrderitemsUpdated.add(sObjOrderItem);
                            }
                        }
                    }
                    /*** 14130963 Ends ***/
                }
            }
               
                // Iterate through the list of orders
                for(Id idKey: mapOrderLineCounts.keySet()){
                    // Get the counts in temporary variables
                    Integer intTotalCounts = mapOrderLineCounts.get(idKey)<>null?mapOrderLineCounts.get(idKey):0;
                    Integer intNACounts = mapOrderLineNACounts.get(idKey)<>null?mapOrderLineNACounts.get(idKey):0;
                    Integer intManualCounts = mapOrderLineManualCounts.get(idKey)<>null?mapOrderLineManualCounts.get(idKey):0;
                    Integer intImmediateCounts = mapOrderLineImmediateCounts.get(idKey)<>null?mapOrderLineImmediateCounts.get(idKey):0;
                    Integer intExistingCounts = mapOrderLineExistingCounts.get(idKey)<>null?mapOrderLineExistingCounts.get(idKey):0;
                    String strOrderStatus = null;
                    if(mapOrderStatus.containsKey(idKey)){
                        strOrderStatus = mapOrderStatus.get(idKey);
                    }
                    // If All lines are NA then Order should be defaulted as Service Provisioned = true and Status = Ready for Submission
                    Order sObjToBeUpdated = new Order(Id=idKey);
                    
                    //Prashant: Updating Order's Create_L_P_Case__c = true if any 1 OrderItem's CWS_ServicesProvisioned__c = false
                    if(orderToUpdateMap.containsKey(idKey)){
                       sObjToBeUpdated.Create_L_P_Case__c = orderToUpdateMap.get(idKey); 
                    }
                     
                    if(!String.isBlank(strOrderStatus) && strOrderStatus<>CWS_ConstantClass.ORDER_STATUS_UNDER_REVIEW){
                        if(intTotalCounts == intExistingCounts){
                        // Update field value : Status = Ready for Submission
                        sObjToBeUpdated.Status = CWS_ConstantClass.ORDER_STATUS_READY_FOR_SUBMISSION;
                        }
                        if(intManualCounts>0){
                        // If there is atleast one manaul line then Status = Pending Fulfillment
                        sObjToBeUpdated.Status = CWS_ConstantClass.ORDER_STATUS_PENDING_FULFILLMENT;
                        }
                        if (intTotalCounts == intNACounts){
                        // Update field value : Service Provisioned = true
                        sObjToBeUpdated.CWS_ServicesProvisioned__c=true;
                        // Update field value : Status = Ready for Submission
                        sObjToBeUpdated.Status = CWS_ConstantClass.ORDER_STATUS_READY_FOR_SUBMISSION;
                        // Store the orders to be updated in a list of Orders
                        }
                        if (intTotalCounts == (intNACounts +intExistingCounts+ intImmediateCounts)){
                        // Update field value : Status = Ready for Submission
                        sObjToBeUpdated.Status = CWS_ConstantClass.ORDER_STATUS_READY_FOR_SUBMISSION;
                        }
                    }   
                    // Store the orders to be updated in a list of Orders
                    lstOrdersToBeUpdated.add(sObjToBeUpdated);
                }
            
            // Create a list of SaveResult instance
            List<Database.SaveResult> saveResults = null;
            List<Database.SaveResult> saveResultsOrderItem = null;
            
            if(!lstOrderitemsUpdated.isEmpty()){
                saveResultsOrderItem = Database.update(lstOrderitemsUpdated,false);
                // Log the save results for faulty ordersItems
                CWS_ExceptionHandler.logDMLSaveResults(saveResultsOrderItem,'CWS_OrderItemHelper','afterInsert','OrderItem','','CWS_OrderItemTrigger');
            }
            
            if(!lstOrdersToBeUpdated.isEmpty()){
                // Invoke Partial DML
                saveResults = Database.update(lstOrdersToBeUpdated,false);
                // Log the save results for faulty orders
                CWS_ExceptionHandler.logDMLSaveResults(saveResults,'CWS_OrderItemHelper','afterInsert','OrderItem','','CWS_OrderItemTrigger');
            }
        } catch (Exception e) {
            CWS_ExceptionHandler.logException(e, 'OrderItem' , 'CWS_OrderItemTriggerHelper','afterInsert' ,'', null, null ,'After Insert' , null);
        }
    }
    /**
     * 
     * @Developer: swachatterjee
     * @Description: Update the Order Start and end dates if the Provisioning date changes
     * @Requirement/Issue: BED - 6891, 6882, 6873,10751
     * 
     */
    public static void beforeUpdate(Map<Id,SObject> newMap, Map<Id,SObject> oldMap){
        Map<Id,Order> mapOrders = null;
        Set<Id> setOrderIds = null;
        try {
            setOrderIds = new Set<Id>();
            
            for(Id idKey: newMap.keySet()){
               OrderItem sObjNewOrderItem =(OrderItem)newMap.get(idKey);
               setOrderIds.add(sObjNewOrderItem.OrderId);    
            }

            if(!setOrderIds.isEmpty()){
                mapOrders = new Map<Id,Order>([select Id,CWS_Quote_Type__c from Order where Id in :setOrderIds]);
            }

            for(Id idKey: newMap.keySet()){
                OrderItem sObjNewOrderItem =(OrderItem)newMap.get(idKey);
                OrderItem sObjOldOrderItem =(OrderItem)oldMap.get(idKey);
                Id idOrder = sObjNewOrderItem.OrderId;
                String strOrderType = null;
                String strTransactionType = sObjNewOrderItem.CWS_Transaction_Type__c;
                String strProvisioningEligibilty = sObjNewOrderItem.CWS_Provisioning_Eligibility__c;
                Integer intSubscriptionTerm = sObjNewOrderItem.CWS_Calculated_Subscription_Term__c <> null?Integer.valueOf(sObjNewOrderItem.CWS_Calculated_Subscription_Term__c) :1;
                if(mapOrders<>null && mapOrders.containsKey(idOrder)){
                    Order sObjOrder = mapOrders.get(idOrder);
                    strOrderType = sObjOrder.CWS_Quote_Type__c;
                }

                 // Start 14061925 - Dedicated Tech Migrated data Does not have flag Checked Dedicated Tech on quote level -- High
  /* if ((strOrderType == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS 
                            || (strOrderType == CWS_ConstantClass.QUOTE_TYPE_AMEND && (strTransactionType == CWS_ConstantClass.TRANSACTION_TYPE_ADD_ON || strTransactionType == CWS_ConstantClass.TRANSACTION_TYPE_SWAPIN || strTransactionType == CWS_ConstantClass.TRANSACTION_TYPE_UPGRADE))) 
                && strProvisioningEligibilty == CWS_ConstantClass.PROVISIONAL_ELIGIBILITY_MANUAL && 
                    // If Provisioning Eligibility is Manual and Service Provisioned is checked then Provisioning Date = Today   
                        sObjNewOrderItem.CWS_ServicesProvisioned__c && !sObjOldOrderItem.CWS_ServicesProvisioned__c){
                            sObjNewOrderItem.CWS_ProvisioningDate__c = System.today();
                            /********************Dedicated Tech Logic*****************/
                          /*  if(sObjNewOrderItem.CWS_Category__c==CWS_ConstantClass.PRODUCT_CATEGORY_DEDICATED_TECH){
                                sObjNewOrderItem.ServiceDate = sObjNewOrderItem.CWS_ProvisioningDate__c;
                                // Need to confirm : the End date for Provisioning
                                sObjNewOrderItem.EndDate = sObjNewOrderItem.ServiceDate.addMonths(intSubscriptionTerm)-1;
                            }
                }*/
                
                if ((strOrderType == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS 
                            || (strOrderType == CWS_ConstantClass.QUOTE_TYPE_AMEND && (strTransactionType == CWS_ConstantClass.TRANSACTION_TYPE_ADD_ON || strTransactionType == CWS_ConstantClass.TRANSACTION_TYPE_SWAPIN || strTransactionType == CWS_ConstantClass.TRANSACTION_TYPE_UPGRADE))) 
                && strProvisioningEligibilty == CWS_ConstantClass.PROVISIONAL_ELIGIBILITY_MANUAL && 
                    // If Provisioning Eligibility is Manual and Service Provisioned is checked then Provisioning Date = Today   
                        sObjNewOrderItem.CWS_ServicesProvisioned__c && !sObjOldOrderItem.CWS_ServicesProvisioned__c){
                            if(sObjNewOrderItem.CWS_Category__c!=CWS_ConstantClass.PRODUCT_CATEGORY_DEDICATED_TECH){
                                sObjNewOrderItem.CWS_ProvisioningDate__c = System.today();
                                }
                            
                }
                if ((strOrderType == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS 
                            || (strOrderType == CWS_ConstantClass.QUOTE_TYPE_AMEND && (strTransactionType == CWS_ConstantClass.TRANSACTION_TYPE_ADD_ON || strTransactionType == CWS_ConstantClass.TRANSACTION_TYPE_SWAPIN || strTransactionType == CWS_ConstantClass.TRANSACTION_TYPE_UPGRADE))) 
                && strProvisioningEligibilty == CWS_ConstantClass.PROVISIONAL_ELIGIBILITY_MANUAL && 
                    // If Provisioning Eligibility is Manual and Service Provisioned is checked then Provisioning Date = Today   
                        sObjNewOrderItem.CWS_ServicesProvisioned__c && sObjNewOrderItem.CWS_Category__c==CWS_ConstantClass.PRODUCT_CATEGORY_DEDICATED_TECH && (sObjNewOrderItem.CWS_ProvisioningDate__c!= null )){
                            /********************Dedicated Tech Logic*****************/
                            if(sObjNewOrderItem.CWS_Category__c==CWS_ConstantClass.PRODUCT_CATEGORY_DEDICATED_TECH){
                                sObjNewOrderItem.ServiceDate = sObjNewOrderItem.CWS_ProvisioningDate__c;
                                // Need to confirm : the End date for Provisioning
                                sObjNewOrderItem.EndDate = sObjNewOrderItem.ServiceDate.addMonths(intSubscriptionTerm)-1;
                            }
                }
        //End 14061925 - Dedicated Tech Migrated data Does not have flag Checked Dedicated Tech on quote level -- High
            }
        } catch (Exception e) {
            CWS_ExceptionHandler.logException(e, 'OrderItem' , 'CWS_OrderItemTriggerHelper','beforeUpdate' ,'', null, null ,'Before Update' , null);
        }
    }
    
   
    /****************** Reusable Methods used for Trigger Helper Logic ***********************/

    /**
     * 
     * @Developer: swachatterjee
     * @Description: Populate the Provisiong Date, Order Item Start and End Dates based on the 
     *               Payment Schedule Driver and Provisioning Eligibility 
     * @Requirement/Issue: BED - 6891, 6882, 6873,10751
     */
   private static OrderItem populateProvisioningDates (Boolean isBeforeInsert, Boolean isBeforeUpdate, 
   OrderItem sObjNewOrderItem,OrderItem sObjOldOrderItem, Map<Id,Order> mapOrders, Map<Id,SBQQ__QuoteLine__c> mapQuoteLines ){
        try {
             // Store the Payment schedule driver in a String value
             String strPaymentScheduleDriver = sObjNewOrderItem.CWS_Payment_Schedule_Driver__c;
             // Store the Provisioning Eligibility in a String value
             String strProvisioningEligibilty = sObjNewOrderItem.CWS_Provisioning_Eligibility__c<>null?sObjNewOrderItem.CWS_Provisioning_Eligibility__c:CWS_ConstantClass.PROVISIONAL_ELIGIBILITY_NA;
             // Store the subscription term in an Integer value
             Integer intSubscriptionTerm = Integer.valueOf(sObjNewOrderItem.CWS_Calculated_Subscription_Term__c);
             // Store the Average number of days in an Integer value
             Integer intAvgNoOfDays = sObjNewOrderItem.CWS_Avg_Number_of_Days__c<>null?Integer.valueOf(sObjNewOrderItem.CWS_Avg_Number_of_Days__c):0;
             // Store the Ramp/Spread/Deferment Period in an Integer value
             Integer intRSDPeriod = sObjNewOrderItem.CWS_Period_for_Ramp_Spread_Deferment__c<>null?Integer.valueOf(sObjNewOrderItem.CWS_Period_for_Ramp_Spread_Deferment__c):0;
             //Capture Order Form creation date -BED-10751
             Date dateOrderFormSignedDate = null;   
            // Capture the Order Type
            String strOrderType = null;
            // Capture the actual Contract term
            Integer intActualContractTerm = 0;
            Id idOrder = sObjNewOrderItem.OrderId;
            SBQQ__QuoteLine__c sObjQuoteLine;
            String strTransactionType = sObjNewOrderItem.CWS_Transaction_Type__c;
                
            if(idOrder<>null && mapOrders <> null && mapOrders.containsKey(idOrder)){
                Order sObjOrder = mapOrders.get(idOrder);
                strOrderType = sObjOrder.CWS_Quote_Type__c;
                intActualContractTerm = Integer.valueOf (sObjOrder.CWS_Actual_Contract_Term__c);
                dateOrderFormSignedDate =sObjOrder.CWS_OF_Signed_Date__c;
            }

            Date dateQLStartDate = null; Date dateQLEndDate = null; Date dateQStartDate = null; Boolean isExisting = false; Boolean isMaster = false;
            Id idQuoteLine = sObjNewOrderItem.SBQQ__QuoteLine__c;
            if(idQuoteLine<>null && mapQuoteLines<>null && mapQuoteLines.containsKey(idQuoteLine)){
                sObjQuoteLine = mapQuoteLines.get(idQuoteLine);
                dateQLStartDate = sObjQuoteLine.SBQQ__EffectiveStartDate__c;
                dateQLEndDate = sObjQuoteLine.SBQQ__EffectiveEndDate__c;
                dateQStartDate = sObjQuoteLine.SBQQ__Quote__r.SBQQ__StartDate__c;
                isExisting = sObjQuoteLine.CWS_Renewed_Line__c;
                isMaster =   sObjQuoteLine.SBQQ__Quote__r.CWS_Master__c;
            } 

               /*Logic for unevenspread - 10788 Start*/
               /*14008857 Uneven spread logic only for NB and Amendment add on and Renewal with change add on '14039139'*/
            if((strOrderType== CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS 
                || (strOrderType == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT && strTransactionType == CWS_ConstantClass.TRANSACTION_TYPE_ADD_ON) 
                    || (strOrderType == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC && !isExisting))
                            && strPaymentScheduleDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_SPREAD && intRSDPeriod >1 && String.isBlank(sObjQuoteLine.CWS_Uneven_Spread_Values__c) ){
                decimal netTotal = sObjQuoteLine.SBQQ__NetPrice__c;
                decimal perPeriodValue = (netTotal/ intRSDPeriod).SetScale(2,System.RoundingMode.DOWN);
                String unevenValues = '';
                // Verify if there is a lost cent value
                sObjNewOrderItem.CWS_Lost_Value__c = netTotal - (perPeriodValue*intRSDPeriod);
                // calculate the first month front loading value
                Decimal decFrontLoadValue = netTotal - (perPeriodValue*(intRSDPeriod-1));
                decimal lostValue = sObjNewOrderItem.CWS_Lost_Value__c;
                // Validate if this is a uneven Spread scenario
                //Updated by Mahak Bansal 8 Sep. 2021 - OBD-57
                if(lostValue >=0 ){
                //if(lostValue <>0 ){
                    for(integer x=0; x<intRSDPeriod; x++){
                        if(x==0){
                            unevenValues = unevenValues + String.ValueOf(decFrontLoadValue) + ';';
                        }
                        else{
                            unevenValues = unevenValues + String.ValueOf(perPeriodValue) + ';';
                        }
                    } 
                    sObjNewOrderItem.CWS_Uneven_Spread_Values__c = unevenValues;
                    sObjNewOrderItem.CWS_Uneven_Spread__c = true;
                }
            }/*Logic for unevenspread - 10788 End*/

            /* Logic for New Business scenarios : BED : 10751 : START */

             // Date Logic for New Business scenario or Order.Quote Type = New Business : START
            if(strOrderType == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS){
                /****************************************Provisioning Date Logic ****************************************/
                // Provisioning Date logic follows only Provisioning Eligibility
                if(isBeforeInsert && strProvisioningEligibilty == CWS_ConstantClass.PROVISIONAL_ELIGIBILITY_NA){
                    // If Provisioning Eligibility is NA, then Provisioning Date = Order Form Signature Date
                    sObjNewOrderItem.CWS_ProvisioningDate__c = dateOrderFormSignedDate;
                    sObjNewOrderItem.CWS_ServicesProvisioned__c = true;
                }else if(isBeforeInsert && strProvisioningEligibilty == CWS_ConstantClass.PROVISIONAL_ELIGIBILITY_IMMEDIATE){
                    //  If Provisioning Eligibility = Immediate, then Order Form Signature Date + Avg.no.of days for provisioning from product
                    sObjNewOrderItem.CWS_ProvisioningDate__c = dateOrderFormSignedDate.addDays(intAvgNoOfDays);
                }else if(isBeforeInsert && strProvisioningEligibilty == CWS_ConstantClass.PROVISIONAL_ELIGIBILITY_MANUAL){
                    // If Provisioning Eligibility is Manual on creation this value will be blank for New Business
                    sObjNewOrderItem.CWS_ProvisioningDate__c = null;
                }

                /****************************************Start and End Date Logic ****************************************/
                // Order Line end date logic uses OF signed Date and Actual Contract Term
                if(isbeforeInsert && intActualContractTerm<>null && intActualContractTerm<>0 && !isMaster){
                    // End date not required for Evergreen Lines
                    //This will be bypassed for Min commit logic
                    if(sObjNewOrderItem.SBQQ__SubscriptionType__c <>null 
                                    && sObjNewOrderItem.SBQQ__SubscriptionType__c != CWS_ConstantClass.Subscription_Type_Evergreen){
                        sObjNewOrderItem.EndDate = dateOrderFormSignedDate.addMonths(intActualContractTerm).addDays(-1);
                              
                    }
                    if(isbeforeInsert && dateOrderFormSignedDate<>null){
                    // Order Line start is based on OFsignedDate and Ramp/Deferment period
                    if((strPaymentScheduleDriver != CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_SPREAD && strPaymentScheduleDriver<>CWS_ConstantClass.PAYMENT_SCHEDULE_MIN_COMMIT_RAMP && strPaymentScheduleDriver<>CWS_ConstantClass.PAYMENT_SCHEDULE_USAGE_BASED_RAMP_ForSane) && intRSDPeriod<>null && intRSDPeriod<>0){
                        sObjNewOrderItem.ServiceDate = dateOrderFormSignedDate.addMonths(intRSDPeriod);
                    }else{
                        sObjNewOrderItem.ServiceDate = dateOrderFormSignedDate.addMonths(0);
                    }
                  }
                }
                
                if(strPaymentScheduleDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_DEFERMENT && intRSDPeriod<>0){
                    sObjNewOrderItem.CWS_ProvisioningDate__c = sObjNewOrderItem.ServiceDate;
                }  
            }
            /* Logic for New Business scenarios : BED : 10751 : END*/
            
            /* Logic for Cancellation & Downgrade Business scenarios : BED : 7017,7008 : START*/
             if(strOrderType == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT){
                /********************Provisioning Date Logic********************/ 
                // For Manual/Any cases if the Provisioning Date will be copied from the Quote line using twin fields
                // Else, Provisioning Date logic follows the Provisioning Eligibility
                if(isBeforeInsert && sObjNewOrderItem.CWS_ProvisioningDate__c==null && strProvisioningEligibilty == CWS_ConstantClass.PROVISIONAL_ELIGIBILITY_NA){
                    // NA, then Order Form Signature Date
                    sObjNewOrderItem.CWS_ProvisioningDate__c = dateOrderFormSignedDate;
                    sObjNewOrderItem.CWS_ServicesProvisioned__c = true;
                }else if(isBeforeInsert &&  sObjNewOrderItem.CWS_ProvisioningDate__c==null && strProvisioningEligibilty == CWS_ConstantClass.PROVISIONAL_ELIGIBILITY_IMMEDIATE){
                    //  Immediate, then Order Form Signature Date + Avg.no.of days for provisioning from product
                    sObjNewOrderItem.CWS_ProvisioningDate__c = dateOrderFormSignedDate.addDays(intAvgNoOfDays);
                }
                /**********************Start Date & End Date Logic **********************/
                // Order line start and end date will be copied from the quote line start and end date 
                // Logic mentioned by CPQ: 
                
                /*BED-10679 Start */
                // Order line start date =  Quote Line start Date
                sObjNewOrderItem.ServiceDate = dateQLStartDate;
                // Quote Line End Date = Quote line End Date
                sObjNewOrderItem.EndDate = dateQLEndDate;
                // Deferment : Amendment
                if(strPaymentScheduleDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_DEFERMENT && intRSDPeriod<>0){
                    sObjNewOrderItem.CWS_ProvisioningDate__c = sObjNewOrderItem.ServiceDate;
                }
              }
            
            /* Logic for Cancellation & Downgrade Business scenarios : BED : 7017,7008, 10679 : END*/
            
            /*Logic for Renewal & Renewal with Change Scenario: BED - 9540,9558 *******/
             
            // Date Logic for Order.Quote Type = Renewal: START : BED - 9549
             if(strOrderType == CWS_ConstantClass.QUOTE_TYPE_RENEWAL){
                if(sObjNewOrderItem.CWS_ProvisioningDate__c==null){
                    sObjNewOrderItem.CWS_ProvisioningDate__c = dateQLStartDate;
                }
                sObjNewOrderItem.ServiceDate = dateQLStartDate;
                sObjNewOrderItem.EndDate = dateQLEndDate;
                sObjNewOrderItem.CWS_ServicesProvisioned__c = true;
             }// Date Logic for Order.Quote Type = Renewal: END

             // Date Logic for Order.Quote Type = Renewal w Change: Start
             if(strOrderType == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC){
                // be it for new or renewed lines the Order line start date = Quote line start date
                sObjNewOrderItem.ServiceDate = dateQLStartDate;
                sObjNewOrderItem.EndDate = dateQLEndDate;
                // the provisioning logic differs in terms of whether the line is renewed or net new
                // For Renewed lines the order line Provisioning date = Quote line start date
                if(isBeforeInsert && isExisting && sObjNewOrderItem.CWS_ProvisioningDate__c == null){
                    sObjNewOrderItem.CWS_ProvisioningDate__c = dateQLStartDate;
                    if(strProvisioningEligibilty== CWS_ConstantClass.PROVISIONAL_ELIGIBILITY_NA){
                        sObjNewOrderItem.CWS_ServicesProvisioned__c = true;
                    }
                // For Net new lines if Quote header start date > Order form signed date
                }else if(!isExisting && isBeforeInsert  && sObjNewOrderItem.CWS_ProvisioningDate__c == null && dateQStartDate>dateOrderFormSignedDate){
                    // Provisioning Date = Quote line start date
                    sObjNewOrderItem.CWS_ProvisioningDate__c = dateQLStartDate;
                    if(strProvisioningEligibilty== CWS_ConstantClass.PROVISIONAL_ELIGIBILITY_NA){
                        sObjNewOrderItem.CWS_ServicesProvisioned__c = true;
                    }
                // For net new lines if the Order form signed date >= Quote Header start date
                }else if(!isExisting && isBeforeInsert && sObjNewOrderItem.CWS_ProvisioningDate__c == null && dateQStartDate <= dateOrderFormSignedDate){
                    // For Provisioining Eligibility, NA Provisioning Date = OF Signed Date
                    if(strProvisioningEligibilty== CWS_ConstantClass.PROVISIONAL_ELIGIBILITY_NA){
                        sObjNewOrderItem.CWS_ProvisioningDate__c = dateOrderFormSignedDate;
                        sObjNewOrderItem.CWS_ServicesProvisioned__c = true;
                    }
                    // For Manual : Populated via twin field
                    // For Immediate OF Signed Date + Avg no of Days
                    else if(strProvisioningEligibilty== CWS_ConstantClass.PROVISIONAL_ELIGIBILITY_IMMEDIATE){
                        sObjNewOrderItem.CWS_ProvisioningDate__c = dateOrderFormSignedDate.addDays(intAvgNoOfDays);
                    }
                }
             }// Date Logic for Order.Quote Type = Renewal w Change: BED - 9549, 9558: END
        } catch (Exception e) {
            CWS_ExceptionHandler.logException(e, 'OrderItem' , 'CWS_OrderItemTriggerHelper','populateProvisioningDates' ,'', null, null ,'Before Update/Before Insert' , null);
        }
        return sObjNewOrderItem;
    }
    /**
     * 
     * @Developer: swachatterjee
     * @Description: to increment the counter in a map of Id and Integer 
     */
    private static Map<Id,Integer> updateMapCounter (Map<Id,Integer> mapObjCounter,Id idKey,Integer increment){
        // Declare integer current number
        Integer intCurrentCounter = 0;
        try {
            // Check if the map is not null, else Instantiate
            if(mapObjCounter==null){
                mapObjCounter = new Map<Id,Integer>();
            }
            // Identify the current counter value
            if(mapObjCounter.containsKey(idKey)){
                intCurrentCounter = mapObjCounter.get(idKey)<>null?mapObjCounter.get(idKey):0;
            }else{
                intCurrentCounter = 0;
            }
            // Increment the counter
            mapObjCounter.put(idKey, (intCurrentCounter+increment));
        } catch (Exception e) {
            CWS_ExceptionHandler.logException(e, 'OrderItem' , 'CWS_OrderItemTriggerHelper','updateMapCounter' ,'', null, null ,'Trigger' , null);
        }
        return mapObjCounter;
    }
     
/**
    * @@Method: beforeInsert
    * @Developer: swachatterjee@deloitte.com
    * @Description: 
    * @Requirement/Issue: BED-10670
     */
    public static void beforeLegacyInsert (List<SObject> lstNewOrderItems){
        Set<Id> setQuotelineIds = null;
        Set<Id> setOrderIds = null;
        Map<Id,SBQQ__QuoteLine__c> mapQuoteLines = new Map<Id,SBQQ__QuoteLine__c>();
        Map<Id,Order> mapOrder = new Map<Id, Order>();
        Set<Id> setProductIds = null;
        Map<Id, Product2> mapProducts = null;
       
        try{
            // Instantiate the Collections
            setQuotelineIds = new Set<Id>();
            setOrderIds = new Set<Id>();
            setProductIds = new Set<Id>();
             mapProducts = new Map<Id,Product2>();
            //Iterate through the list of Order items in context
            for(SObject sObjInstance: lstNewOrderItems){
                OrderItem sObjOrderItem = (OrderItem)sObjInstance;
                setQuotelineIds.add(sObjOrderItem.SBQQ__QuoteLine__c);
                setOrderIds.add(sObjOrderItem.OrderId);
                setProductIds.add(sObjOrderItem.Product2Id);
            }
            // Query the quotelines
            // Swagata note: This can be optimized: Remove this query and add twin fields
             if(!setQuotelineIds.isEmpty()){
                mapQuoteLines = new Map<Id,SBQQ__QuoteLine__c> ([select Id,CWS_NetTotal__c, CWS_Price_Per_Billing_Period__c, CWS_Renewed_Line__c,SBQQ__Existing__c, SBQQ__EffectiveStartDate__c,SBQQ__EffectiveEndDate__c,SBQQ__Quote__r.SBQQ__StartDate__c, SBQQ__ListTotal__c,SBQQ__NetTotal__c, CWS_Calculated_Subscription_Term__c, SBQQ__RegularTotal__c,SBQQ__Quote__r.SBQQ__BillingFrequency__c,SBQQ__NetPrice__c,SBQQ__SubscriptionTerm__c,CWS_Payment_Schedule_Driver__c,CWS_Period_for_Ramp_Spread_Deferment__c,SBQQ__Product__r.CWS_ChargeType__c,SBQQ__Product__r.CWS_Implementation_Spread_Eligibility__c, CWS_Billing_Term__c, CWS_NetPrice__c, CWS_RegularPrice__c from SBQQ__QuoteLine__c where Id in:setQuotelineIds LIMIT 20000]);
            }
            if(!setOrderIds.isEmpty()){
                mapOrder = new Map<Id,Order>([Select id,CWS_Master__c from Order where id in :setOrderIds limit 20000]);
            }
            if(!setProductIds.isEmpty()){
                mapProducts = new Map<Id,Product2>([select id, name, SBQQ__PricingMethod__c, SBQQ__BlockPricingField__c, CWS_Charge_Model__c ,CWS_ProductCode__c, CWS_Additional_Restrictions__c from Product2 where id in: setProductIds]);
            }
            for(SObject sObjInstance: lstNewOrderItems){
                OrderItem sObjOrderItem = (OrderItem)sObjInstance;
                Order sObjOrder = mapOrder.get(sObjOrderItem.OrderId) ;
                sObjOrderItem.CWS_ServicesProvisioned__c =true;
                sObjOrderItem.CWS_ProvisioningDate__c = sObjOrderItem.ServiceDate;
                Product2 sObjProd = mapProducts.get(sObjOrderItem.Product2Id);
                String chargeModel = sObjProd.CWS_Charge_Model__c;
                String pricingMethod = sObjProd.SBQQ__PricingMethod__c;
                String pricingField = sObjProd.SBQQ__BlockPricingField__c;
                Decimal netPrice = null;
                Decimal quantity = null;
                
                // Capture the Quote line id 
                Id idQuoteLine = sObjOrderItem.SBQQ__QuoteLine__c;
                SBQQ__QuoteLine__c sObjQuoteLine = null;
                 Integer multiplicationFactor;
                // Validate if the quote line id is blank
                if(!String.isBlank(idQuoteLine) && mapQuoteLines.containsKey(idQuoteLine)){
                    sObjQuoteLine = mapQuoteLines.get(idQuoteLine);
                }
                // Populate the List, Regular and Net total fields
                sObjOrderItem.CWS_RegularTotal__c = sObjQuoteLine.SBQQ__RegularTotal__c <> null ? sObjQuoteLine.SBQQ__RegularTotal__c: 0.0d;
                sObjOrderItem.CWS_ListTotal__c = sObjQuoteLine.SBQQ__ListTotal__c <> null ? sObjQuoteLine.SBQQ__ListTotal__c: 0.0d;
                //BED-13713
                sObjOrderItem.UnitPrice = sObjQuoteLine.CWS_NetPrice__c <> null ? sObjQuoteLine.CWS_NetPrice__c: 0.0d;
                 
                 //Bed-13371
                 Boolean master = sObjOrder.CWS_Master__c;
                 Boolean excludateFromNetTotal = sObjOrderItem.CWS_Exclude_from_Net_Total__c;
                 if(excludateFromNetTotal && sObjQuoteLine.CWS_RegularPrice__c != null){
                    netPrice = sObjQuoteLine.CWS_RegularPrice__c;
                 }else{
                    if(sObjQuoteLine.CWS_NetPrice__c != null){
                      netPrice = sObjQuoteLine.CWS_NetPrice__c;
                    }
                 }            
                                 
                 /**
                  * Calculate Price per billing period based on CWS_Billing Term and charge type
                  */ 
                 calcPricePerBillingPeriod( sObjOrderItem, sObjQuoteLine.CWS_Price_Per_Billing_Period__c, sObjQuoteLine.CWS_Billing_Term__c, sObjQuoteLine.SBQQ__Product__r.CWS_ChargeType__c , 
                                sObjOrderItem.CWS_Calculated_Subscription_Term__c,netPrice , sObjOrderItem.CWS_Regular_Unit_Price__c, sObjQuoteLine.CWS_Payment_Schedule_Driver__c, sObjQuoteLine.CWS_Period_for_Ramp_Spread_Deferment__c, master, excludateFromNetTotal);
                   Decimal netTotal; 
                
                String billcycle = sObjOrderItem.CWS_Bill_Cycle_Type__c;
                String psd = sObjOrderItem.CWS_Payment_Schedule_Driver__c;
                Decimal ppsd = sObjOrderItem.CWS_Period_for_Ramp_Spread_Deferment__c;
                String chargeType = sObjOrderItem.SBQQ__ChargeType__c;
                Date startDate = sObjOrderItem.ServiceDate;
                Decimal noOfDaysIn1stMonth = date.daysInMonth(startDate.year(),startDate.month());
                Decimal startDay = startDate.day();
                Date billingEndDate;
                String unevenValues =  sObjOrderItem.CWS_Uneven_Spread_Values__c;  
                Boolean unevenSpread = sObjOrderItem.CWS_Uneven_Spread__c;
                
                if(psd== CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_SPREAD){
                 if(ppsd <> null && ppsd >0){
                    billingEndDate = (startDate.addMonths(Integer.valueOf(ppsd)));
                 }
                 else{
                        billingEndDate = (startDate.addMonths(1));
                     }
                 }
               else if(sObjQuoteLine.SBQQ__Product__r.CWS_Implementation_Spread_Eligibility__c && (String.isBlank(psd))){
                        billingEndDate = (startDate.addMonths(1));
               }
               else{
                     billingEndDate = sObjOrderItem.EndDate;
                   }
                
                Date endDate; 
                 if(psd!= null && psd == 'Spread'){
                    endDate = billingEndDate.addDays(-1); 
                    }else{
                         endDate = sObjOrderItem.EndDate; 
                         }
                
                
                Decimal noOfDaysInLastMonth = endDate<>null ? date.daysInMonth(endDate.year(),endDate.month()) : null;         
               
                Decimal term = sObjQuoteLine.CWS_Calculated_Subscription_Term__c;
                Boolean isTermInteger = Integer.valueOf(term)==term ;
                Boolean proRate;
                if(startDay <> 1 && (String.isBlank(billcycle) || billcycle =='DefaultFromCustomer')){
                   
                    if(chargeType != 'One-Time' || psd=='Spread'){
                        proRate = true;
                    }else{
                        proRate = false;
                    }
                }else{
                    proRate = false;
                }
                 if(Test.isRunningTest()){
                    isTermInteger= false;
                }
                //Check if Product has block pricing then take the quantity as 1 else original quantity
                if(pricingMethod == 'Block' && pricingField!=null){
                    quantity = 1;
                }else{
                    quantity = sObjOrderItem.SBQQ__OrderedQuantity__c;
                }
                
                 if( String.isblank(unevenValues) && !unevenSpread && ((proRate && noOfDaysInLastMonth<>null && noOfDaysIn1stMonth<>noOfDaysInLastMonth) || !isTermInteger)  && 
                        (chargeModel == 'Per Unit Pricing' || chargeModel == 'Flat Fee Pricing') && 
                        (sObjQuoteLine.SBQQ__Product__r.CWS_ChargeType__c == CWS_ConstantClass.ChargeType_Recurring || 
                                (sObjQuoteLine.CWS_Payment_Schedule_Driver__c == 'Spread' && sObjQuoteLine.SBQQ__Product__r.CWS_Implementation_Spread_Eligibility__c))){
                                if(sObjOrderItem.CWS_Exclude_from_Net_Total__c){
                                        netTotal = sObjQuoteLine.SBQQ__RegularTotal__c;
                                    }else{
                                       netTotal = sObjQuoteLine.CWS_NetTotal__c; 
                                    }
                    proRateCalculation(sObjOrderItem,sObjQuoteLine.CWS_Payment_Schedule_Driver__c, sObjOrderItem.CWS_Period_for_Ramp_Spread_Deferment__c, 
                                          sObjOrderItem.ServiceDate,sObjOrderItem.EndDate, billingEndDate, 
                                               sObjQuoteLine.CWS_Billing_Term__c, netTotal, sObjQuoteLine.CWS_Calculated_Subscription_Term__c,
                                                                                      quantity, sObjOrderItem.CWS_Price_Per_Billing_Period__c);
                } 
             }
           } catch (Exception e) {
               CWS_ExceptionHandler.logException(e, 'OrderItem' , 'CWS_OrderItemTriggerHelper','beforeInsert' ,'', null, null ,'Before Insert' , null);
        }
    }
    
    
    /**
    * @@Method: calcPricePerBillingPeriod
    * @Developer: Aditya
    * @Description: Reusable method for trigger helper to calculate price per billing period 
     */

     public static void calcPricePerBillingPeriod(OrderItem sObjOrderItem, Decimal quoteLineppBP, String billingTerm, String chargeType, 
            Decimal subsTerm, Decimal netPrice, Decimal regNetPrice, String psDriver, Decimal rsdPeriod, Boolean master, Boolean excludateFromNetTotal){
             try{   System.debug('**********In Billing Period Methid******');
                      Integer multiplicationFactor = monthsPerBillingPeriod(billingTerm);
                  
                //BED-10930- Starts- Price per billing frequency logic
                    /**
                     * If Charge Type = Recurring 
                     * The Price Per Billing Period = Net Unit Price / Subscription Factor * Multiplication Factor
                     */
                    if(chargeType == CWS_ConstantClass.ChargeType_Recurring && netPrice <> null && subsTerm <> null 
                                            && subsTerm <> 0 && !String.isBlank(billingTerm) ){
          
                       // Calculate the Price per billing period
                      sObjOrderItem.CWS_Price_Per_Billing_Period__c = quoteLineppBP;
                      if(subsTerm!=null && regNetPrice!= null && multiplicationFactor!=null){
                        sObjOrderItem.CWS_RegularUnit_Price_per_billing_period__c =  (regNetPrice/subsTerm)*multiplicationFactor;  
                      }
                    }
                    /**
                    * If the Charge Type of the product is One-Time and Spread period is mentioned
                    * The Price per billing period = Net Unit Price*1/Period of Spread
                    */
                   else if(chargeType == CWS_ConstantClass.ChargeType_OneTime && psDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_SPREAD && rsdPeriod <> null){
                        // If Spread period is non zero
                        if( rsdPeriod <> 0 ){
                            sObjOrderItem.CWS_Price_Per_Billing_Period__c= (netPrice/rsdPeriod)*multiplicationFactor;
                            sObjOrderItem.CWS_RegularUnit_Price_per_billing_period__c = (regNetPrice/rsdPeriod)*multiplicationFactor; 
                        }
                        // If Spread period is zero
                        else if (rsdPeriod == 0){
                            sObjOrderItem.CWS_Price_Per_Billing_Period__c= (netPrice);
                            sObjOrderItem.CWS_RegularUnit_Price_per_billing_period__c = regNetPrice; 
                        }
                   }/**
                    * If the Charge Type of the product is One-Time and the Payment Schedule Driver is deferment
                    * The Price per billing period = Net Unit Price*1/1 = Net Unit price
                    */
                    else if(chargeType == CWS_ConstantClass.ChargeType_OneTime && psDriver == CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_DEFERMENT){
                        sObjOrderItem.CWS_Price_Per_Billing_Period__c= netPrice;
                        sObjOrderItem.CWS_RegularUnit_Price_per_billing_period__c = regNetPrice; 
                    }
                   /**
                    * If the Charge Type of the product is One-Time and Spread period is NOT mentioned
                    * The Price per billing period = Net Unit Price*1/1 = Net Unit Price
                    */
                   else if(chargeType == CWS_ConstantClass.ChargeType_OneTime && psDriver == null && rsdPeriod == null ){
                        sObjOrderItem.CWS_Price_Per_Billing_Period__c= netPrice; 
                        sObjOrderItem.CWS_RegularUnit_Price_per_billing_period__c = regNetPrice;                        
                        }
                    /**
                    * If the Charge Type of the product is Usage
                    */
                   else if(chargeType == CWS_ConstantClass.ChargeType_Usage && multiplicationFactor<>null){
                       sObjOrderItem.CWS_RegularUnit_Price_per_billing_period__c =  (regNetPrice/subsTerm)*multiplicationFactor;
                       if(excludateFromNetTotal && sObjOrderItem.CWS_RegularUnit_Price_per_billing_period__c != null){
                         sObjOrderItem.CWS_Price_Per_Billing_Period__c =  sObjOrderItem.CWS_RegularUnit_Price_per_billing_period__c;
                       }else{
                         sObjOrderItem.CWS_Price_Per_Billing_Period__c= quoteLineppBP;
                       }
                   }
            }
            catch(Exception e){
                 CWS_ExceptionHandler.logException(e, 'OrderItem' , 'CWS_OrderItemTriggerHelper','calcPricePerBillingPeriod' ,'', null, null ,'Price per billing period' , null);
            }       
     }
     
     /**
    * @@Method: proRateCalculation
    * @Developer: Aditya
    * @Description: Reusable method for trigger helper to calculate price adjustment date and price for last billing period 
     */
     public static void proRateCalculation(OrderItem obj, String psd, Decimal spreadPeriod, Date sdate, Date actualEndDate,  Date billingEndDate, String billingterm, Decimal netTotal,  Decimal calcSubsTerm, Decimal quantity, Decimal ppbp){
      System.debug('********IN PRORATE CALC******');
         Decimal yearOf1stMonth= NULL;
      Decimal firstMonth = null;
      Date wholeMonthStart = null;
      Decimal fractional1stMonth = null;
      Date edate;
         if(psd!= null && psd == CWS_ConstantClass.PAYMENT_SCHEDULE_DRIVER_SPREAD){
            edate = billingEndDate.addDays(-1); 
            }
         else{
            edate = actualEndDate; 
            } 
      try{
          Decimal noOfDaysIn1stMonth,noOfDaysInLasttMonth;
        if(sdate!=null){    
              noOfDaysIn1stMonth = date.daysInMonth(sdate.year(),sdate.month());
             Decimal noOfDaysRemaining1stMonth = noOfDaysIn1stMonth - sdate.day() +1;
             fractional1stMonth = noOfDaysRemaining1stMonth/noOfDaysIn1stMonth;
             wholeMonthStart = sdate + Integer.valueOf(noOfDaysRemaining1stMonth);
             firstMonth = wholeMonthStart.month();
             yearOf1stMonth = wholeMonthStart.year();
        }
        if(edate!=null){
            noOfDaysInLasttMonth = date.daysInMonth(edate.year(),edate.month());
            Decimal noOfDaysRemainingLastMonth = edate.day();
            Decimal fractionalLastMonth = noOfDaysRemainingLastMonth/noOfDaysInLasttMonth;
            Date wholeMonthEnd = edate - Integer.valueOf(noOfDaysRemainingLastMonth);
            Decimal yearOfLastMonth = wholeMonthEnd.year();
            Decimal lastMonth = wholeMonthEnd.month();
            Decimal noOfWholeMonths = null;
            
            if(yearOf1stMonth == yearOfLastMonth){
                noOfWholeMonths = lastMonth - firstMonth +1;
                 }
            else if(yearOf1stMonth< yearOfLastMonth && lastMonth<firstMonth){
                noOfWholeMonths = 12 - firstMonth + lastMonth + 1 + 12*(yearOfLastMonth - (yearOf1stMonth +1));
            }
            else{
                noOfWholeMonths = 12*(yearOfLastMonth - yearOf1stMonth) + lastMonth - firstMonth + 1;
            }
            Decimal pricePerMonth;
            Decimal noOfWholeBP;    
            Decimal monthsPerBP = monthsPerBillingPeriod(billingterm);
            if(ppbp!= null && monthsPerBP!=0 && monthsPerBP!=null){
                 pricePerMonth = ppbp/monthsPerBP;
                 noOfWholeBP = Math.floor(noOfWholeMonths/monthsPerBP);
            }
            //Check for RoundingMode
            Decimal fractFirstMonthTotal = (pricePerMonth*fractional1stMonth*quantity).SetScale(2);
            Decimal wholePeriodTotal = (noOfWholeBP*ppbp*quantity).SetScale(2);
            Decimal remainingMonths = noOfWholeMonths - (monthsPerBP*noOfWholeBP);
            if(quantity!=0){
            Decimal divisionFactor = (quantity*(remainingMonths + fractionalLastMonth))/monthsPerBP;
            Decimal reamainingAmount = netTotal - (fractFirstMonthTotal + wholePeriodTotal);
            Decimal period;
                if(calcSubsTerm <=1 && sdate.month() == edate.month()){
                    period = (edate.day() - sdate.day() +1)/noOfDaysIn1stMonth;
                    Decimal dFactor = (quantity*period)/monthsPerBP;
                    obj.CWS_Price_Per_Billing_Period__c = netTotal/dFactor;
                    System.debug('CALCULATED HERE 1');
                    }
                //14104744
                //Calculating price per billing period where term is less than the billing period, No adjustment required   
                else if(calcSubsTerm >1 && calcSubsTerm <= monthsPerBP){
                    period = fractional1stMonth + fractionalLastMonth + noOfWholeMonths;
                    Decimal dFactor = (quantity*period)/monthsPerBP;
                    obj.CWS_Price_Per_Billing_Period__c = netTotal/dFactor;
                    System.debug('CALCULATED HERE 2');
                }
                else{  
                    obj.CWS_Price_For_Last_Billing_Period__c = reamainingAmount/divisionFactor;
                    obj.CWS_PriceAdjustmentDate__c = wholeMonthStart.addMonths(Integer.valueOf(monthsPerBP*noOfWholeBP));
                    }    
           }    
        }
            
        }Catch(Exception e){
            CWS_ExceptionHandler.logException(e, 'OrderItem' , 'CWS_OrderItemTriggerHelper','proRateCalculation' ,'', null, null ,'Pro Rate calculation' , null);
        }
        
     }
     
     public static Integer monthsPerBillingPeriod(String billingTerm){
        Integer multiplicationFactor;
                  
                       if(billingTerm== CWS_ConstantClass.BillingTerm_Monthly){
                        // If the Billing Term is Monthly; Billing Frequency Mult. Factor = 1    
                            multiplicationFactor =1;
                       }
                       else if(billingTerm == CWS_ConstantClass.BillingTerm_Quarterly){
                        // If the Billing Term is Monthly; Billing Frequency Mult. Factor = 3   
                            multiplicationFactor =3;
                       }
                       else if(billingTerm == CWS_ConstantClass.BillingTerm_SemiAnnual){
                        // If the Billing Term is Semi-Annual; Billing Frequency Mult. Factor = 6      
                            multiplicationFactor =6;
                       }
                       else if(billingTerm == CWS_ConstantClass.BillingTerm_Annual){
                        // If the Billing Term is Annual; Billing Frequency Mult. Factor = 12         
                            multiplicationFactor =12;
                       }
                       else if(billingTerm == CWS_ConstantClass.BillingTerm_BiAnnual){
                        // If the Billing Term is Annual; Billing Frequency Mult. Factor = 24                           
                            multiplicationFactor =24;
                       }
                       else if(billingTerm == CWS_ConstantClass.BillingTerm_TriAnnual){
                        // If the Billing Term is Annual; Billing Frequency Mult. Factor = 36                           
                            multiplicationFactor =36;
                       }
                       else if(billingTerm == CWS_ConstantClass.BillingTerm_OneTime){
                            multiplicationFactor =1;
                       }
            return multiplicationFactor;
     }

}