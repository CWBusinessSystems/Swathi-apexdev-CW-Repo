/*Class Name: CWS_OrderTriggerHelper
*Description: Helper Class for CWS_OrderTriggerHandler
*Created By: swachatterjee
*Created On: 4/5/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*swachatterjee          4/3/2020            -                  Initial Version
*swachatterjee          4/6/2020        BED - 1278             beforeInsert()  
*swachatterjee          4/10/2020       BED - 1287             Updated beforeInsert() to include Ready for submission scenario
*swachatterjee          5/4/2020        BED - 1350             Updated the logic on AfterUpdate to invoke Callout  
*npillalamarri           5/13/2020      BED - 4997             Updated beforeUpdate() to check contracted when status is changed to provisioned                       
*chanmishra             5/27/2020       BED - 5500             created new Function to pull LE-Companycodeinfo & updated beforeInsert to populate Company code.
*swachatterjee          6/14/2020       BED - 9549,9558        The Renewed From and First order relationship
*swachatterjee			6/30/2020		BED - 10670			   Filter logic for Legacy Order                                                                                                                                        
*/
public class CWS_OrderTriggerHelper {

    /**
    * @Method: beforeInsert
    * @Developer: swachatterjee@deloitte.com
    * @Description: Trigger logic on Before Insert event of an Order
     */
    public static void beforeInsert (List<SObject> lstNewOrders){
        Set<Id> setRelatedQuoteIds = null;
        Set<Id> setAccountIds = null;
        //BED-5500
            map<string,string> getTaxCompanyCode = getTaxCompanyCode();
        //@Issue: BED-1278
        // Update the PO Number on Order
        // Update the Review Reason = Missing PO and and Status = Under Review, if the 
        // PO Number is missing and the related Bill to Accunt has PO required = TRUE
        // BED - 1278: START
        try {
            setRelatedQuoteIds = new Set<Id>();
            setAccountIds = new Set<Id>();
            
            // Iterate through the Context variable : Trigger.New
            // Capture the Unique Quote Ids
            // Note: Order - Quote is One to One relationship
            for(SObject sObj: lstNewOrders){
                Order sObjOrder = (Order)sObj;
                    setRelatedQuoteIds.add(sObjOrder.SBQQ__Quote__c);
                    setAccountIds.add(sObjOrder.CWS_Bill_To_Account__c);
                    setAccountIds.add(sObjOrder.CWS_Ship_To_Account__c);
            }
            Map<Id,SBQQ__Quote__c> mapQuotes=null;
            // Query the information for the related quote
            // BED- 5500 added LE info for the related quote
            if(!setRelatedQuoteIds.isEmpty()){
                mapQuotes = new Map<Id,SBQQ__Quote__c> ([select Id, SBQQ__StartDate__c,CWS_PO_Number__c, CWS_OF_Signed_Date__c,CWS_OF_Signed_Override_Date__c,CWS_Master__c,
                                                        CWS_Bill_To_Account__c,CWS_Bill_To_Account__r.CWS_Purchase_Order_Required__c,CWS_Legal_Entity__c,
                                                        SBQQ__Opportunity2__c,CWS_Transaction_Reason__c,
                                                        SBQQ__Opportunity2__r.SBQQ__RenewedContract__c,
                                                        SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.CWS_OriginalOrder__c,
                                                        SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.CWS_OriginalOrder__r.CWS_FirstOrder__c,
                                                        SBQQ__Opportunity2__r.SBQQ__AmendedContract__c,
                                                        SBQQ__Opportunity2__r.SBQQ__AmendedContract__r.CWS_OriginalOrder__c,
                                                        SBQQ__Opportunity2__r.SBQQ__AmendedContract__r.CWS_OriginalOrder__r.CWS_ZuoraSubscriptionNumber__c 
                                                        from SBQQ__Quote__c where Id in:setRelatedQuoteIds LIMIT 10000]);
            }
           
            map<Id,Account> mapAccounts = null;
            if(!setAccountIds.isEmpty()){
                mapAccounts = new Map<Id,Account>([select Id,BillingCity,BillingCountry,CWS_Need_Recurring__c,
                                                BillingCountryCode,BillingGeocodeAccuracy,BillingLatitude,BillingLongitude,
                                                BillingPostalCode,BillingState,BillingStateCode,BillingStreet 
                                                from Account where Id in: setAccountIds LIMIT 10000]);                        
            }

            // Iterate the List of Orders in Context (Trigger.New)
            for(SObject sObj: lstNewOrders){
                    Order sObjOrder = (Order) sObj;
                    Id idRelatedQuote = sObjOrder.SBQQ__Quote__c;
                    SBQQ__Quote__c relatedQuoteObj = null;
					Date ofSignedDate = null;
					Account billToAcc = mapAccounts.get(sObjOrder.CWS_Bill_To_Account__c);
					String reviewReason = null;

                    // populate the Address information from Account
                    sObjOrder = populateAddressDetails(sObjOrder,mapAccounts);

                    // Verify if the quote id is not blank on Order
                    if(idRelatedQuote<>null && !String.isBlank(idRelatedQuote)&& mapQuotes<>null && mapQuotes.containsKey(idRelatedQuote)){
                        relatedQuoteObj = mapQuotes.get(idRelatedQuote);
                    }
                    // BED : 10751, 9558, 9549, 7017, 7008
                    // For first track quote: take : Order form signed date = today
                    ofSignedDate = relatedQuoteObj.CWS_OF_Signed_Override_Date__c <> null ? relatedQuoteObj.CWS_OF_Signed_Override_Date__c : System.today();
					
					//BED-12343 : For Ingram orders order start date should be first of the month of OfSignedDate
                    if(billToAcc.CWS_Need_Recurring__c){
                    	sObjOrder.CWS_OF_Signed_Date__c	 = ofSignedDate.toStartOfMonth();
                    }else{
                        sObjOrder.CWS_OF_Signed_Date__c = ofSignedDate;
                    }
					
                    // Check if the related quote instance is available
                    if(relatedQuoteObj<>null){
                       //Skip this logic for legacy min commit Quotes
                      if(!relatedQuoteObj.CWS_Master__c){	
                        // Default EffeciveDate = Order form Signed Date/Creation Date
                        if(sObjOrder.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWAL || sObjOrder.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC){
                            sObjOrder.EffectiveDate = relatedQuoteObj.SBQQ__StartDate__c;
                        }else if(sObjOrder.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT){
                            sObjOrder.EffectiveDate = sObjOrder.CWS_MinLineStartDate__c;
                        }else{
                            sObjOrder.EffectiveDate = sObjOrder.CWS_OF_Signed_Date__c;
                        }
                      }else if(sObjOrder.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT){
                        sObjOrder.EffectiveDate = sObjOrder.CWS_MinLineStartDate__c;
                        } 
					  
                        // Capture PO Number in a local variable
                        String strPONumber = relatedQuoteObj.CWS_PO_Number__c;
                        // If PO Number on QUote is available then populate on Order
                        // Default the PO Number from Quote
                        if(!String.isBlank(strPONumber)){
                            sObjOrder.PONumber = strPONumber;
                        }
                        // Order status = Ready for Submission
                        // Else Update Review Reason = Missing PO / Status = Under Review
						//14039650
                        if(String.isBlank(strPONumber) 
									&& sObjOrder.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS
                                    && relatedQuoteObj.CWS_Bill_To_Account__c<>null
									&& relatedQuoteObj.CWS_Bill_To_Account__r.CWS_Purchase_Order_Required__c==CWS_ConstantClass.ACCOUNT_PO_REQUIRED_YES){
                            // Update the Order Review Reason = 'Missing PO'
                            sObjOrder.Status=CWS_ConstantClass.ORDER_STATUS_UNDER_REVIEW;
                            sObjOrder.CWS_ReviewReason__c = CWS_ConstantClass.ORDER_REVIEW_REASON_MISSING_PO;
							reviewReason =  sObjOrder.CWS_ReviewReason__c;
                        }
                        
						//Recommit CR
                         if(relatedQuoteObj.CWS_Master__c 
                         		&& (sObjOrder.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS || sObjOrder.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC)
                         		&& relatedQuoteObj.CWS_Transaction_Reason__c == CWS_ConstantClass.TRANSACTION_REASON_RECOMMIT){
                            // Update the Order Review Reason = 'Missing PO'
                            sObjOrder.Status=CWS_ConstantClass.ORDER_STATUS_UNDER_REVIEW;
                            //If review reason has value as missing PO then append the recommit value
                            if(reviewReason != null){
                            	sObjOrder.CWS_ReviewReason__c = reviewReason+';'+CWS_ConstantClass.TRANSACTION_REASON_RECOMMIT;
                            }
                            else{
                            	sObjOrder.CWS_ReviewReason__c = CWS_ConstantClass.TRANSACTION_REASON_RECOMMIT;
                            }
                        }
						
                        /*
                         * Added as part of BED-5500
                         * Set localvariable for Legal Entity
                         * If LE is not blank, Set the Company code for the Legal Entity code.
                        */
                        String strLegalEntity = relatedQuoteObj.CWS_Legal_Entity__c;
                        if(!String.isBlank(strLegalEntity)) {
                            sObjOrder.CWS_Company_Code__c = getTaxCompanyCode.get(strLegalEntity);
                        }
                        
                        /**
                         * @Developer : swachatterjee
                         * @Description:Renewal Order Logic first order and Renewed from Order relationship logic
                         * @Issue : BED - 9558,9549
                         */
                        if((sObjOrder.CWS_Quote_Type__c==CWS_ConstantClass.ORDER_TYPE_RENEWAL || sObjOrder.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC)
                        && relatedQuoteObj.SBQQ__Opportunity2__c <> null 
                        && relatedQuoteObj.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c <>null
                        ){
                            Id idContract = relatedQuoteObj.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c;
                            // Capture the related Contract Id
                            //sObjOrder.ContractId = idContract;
                            // Get the Original Order from the immediate Contract
                            Id idOriginalOrder = relatedQuoteObj.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.CWS_OriginalOrder__c;
                            if(idOriginalOrder<>null){
                                // Get the first order from the Original order
                                Id idFirstOrder = relatedQuoteObj.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.CWS_OriginalOrder__r.CWS_FirstOrder__c;
                                if(idFirstOrder <> null){
                                // If First ORder is available on Immediate original order ; copy the first order
                                sObjOrder.CWS_FirstOrder__c = idFirstOrder;
                                }else{
                                    // If the first order is not available on Immediate Original Order ; Copy the original order id
                                    sObjOrder.CWS_FirstOrder__c = idOriginalOrder;
                                    }
                                sObjOrder.CWS_RenewedFromOrder__c = idOriginalOrder;
                                }
                        }

                        // Service Provisioned : should be checked for Order Type = Renewal (No touch or Renewal wo Change)
                        // BED: 9549 : START
                        if (sObjOrder.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWAL) {
                            sObjOrder.CWS_ServicesProvisioned__c = true;
                        }
                        // BED: 9549 : END

                        // Renewal Implementation for : (9549.9558) : END
                        /**
                         * @Developer: swachatterjee
                         * @Description: Zuora Subscription Number: CWS_ZuoraSubscriptionNumber__c
                         * Amendment logic: During Amendment: Following information should flow from Original Order
                         */
                        // If Order type = Amendment then Populate Original Order Id from Opportunity.AmendedContract
                        if(sObjOrder.CWS_Quote_Type__c == CWS_ConstantClass.ORDER_TYPE_AMENDMENT
                        && relatedQuoteObj.SBQQ__Opportunity2__c <> null 
                        && relatedQuoteObj.SBQQ__Opportunity2__r.SBQQ__AmendedContract__c <> null 
                        ){
							 if(!sObjOrder.CWS_AddOnEvergreen__c){
                            // Copy the Copy the amended contract id to ContractId
                            //sObjOrder.ContractId = relatedQuoteObj.SBQQ__Opportunity2__r.SBQQ__AmendedContract__c;
                            // Copy the Original Order Id from Amended Contract to Order
                            if(relatedQuoteObj.SBQQ__Opportunity2__r.SBQQ__AmendedContract__r.CWS_OriginalOrder__c <> null ){
                                sObjOrder.CWS_OriginalOrder__c = relatedQuoteObj.SBQQ__Opportunity2__r.SBQQ__AmendedContract__r.CWS_OriginalOrder__c ;
                            }
                            // Copy the Zuora Subscription Number from quote to Order
                            if(relatedQuoteObj.SBQQ__Opportunity2__r.SBQQ__AmendedContract__r.CWS_OriginalOrder__r.CWS_ZuoraSubscriptionNumber__c <>null){
                                sObjOrder.CWS_ZuoraSubscriptionNumber__c= relatedQuoteObj.SBQQ__Opportunity2__r.SBQQ__AmendedContract__r.CWS_OriginalOrder__r.CWS_ZuoraSubscriptionNumber__c; 
                            } 
						  }
						}
                       }
                }
            
        } catch (Exception e) {
            CWS_ExceptionHandler.logException(e, 'Order' , 'CWS_OrderTriggerHelper','beforeInsert' ,'', null, null ,'Before Insert' , null);
        }
        // BED - 1278 : END
    }


    /**
    * @Method: beforeUpdate
    * @Developer: swachatterjee@deloitte.com
    * @Description: Trigger logic on Before Update event of an Order
     */
    public static void beforeUpdate(Map<Id, SObject> newMap, Map<Id, SObject> oldMap){
        try {
            // Iterate through the Orders to be updated
            for(Id idKey: newMap.keySet()){
                Order sObjNewOrder = (Order) newMap.get(idKey);
                Order sObjOldOrder = (Order) oldMap.get(idKey);
                
                // If the Service Provisioned is checked
                if(!sObjOldOrder.CWS_ServicesProvisioned__c 
                    && sObjNewOrder.CWS_ServicesProvisioned__c 
                    && sObjOldOrder.Status<>CWS_ConstantClass.ORDER_STATUS_PROCESSED
                    && sObjOldOrder.Status<>CWS_ConstantClass.ORDER_STATUS_PARTIALLY_PROCESSED
                    && sObjOldOrder.Status<>CWS_ConstantClass.ORDER_STATUS_FAILED
                    && sObjOldOrder.Status<>CWS_ConstantClass.ORDER_STATUS_READY_FOR_SUBMISSION){
                    // If Number of Lines WO dates populated >0 then 
                    // Put Order Status = Pending Fulfillment
                    if(sObjNewOrder.CWS_LineToBeProvisioned__c>0 || sObjNewOrder.CWS_LinesWODatesPopulated__c>0){
                        sObjNewOrder.Status=CWS_ConstantClass.ORDER_STATUS_PENDING_FULFILLMENT;
                    } 
                    // If Number of Lines w/o dates =0 and provisioning dates are populated for all except NA
                    // Put Order Status = Ready for Submission
                    else if(sObjNewOrder.CWS_LinesWODatesPopulated__c==0 && sObjNewOrder.CWS_LineToBeProvisioned__c==0){
                        sObjNewOrder.Status=CWS_ConstantClass.ORDER_STATUS_READY_FOR_SUBMISSION;
                    }
                }
                //BED:4997 Starts
                if(sObjOldOrder.Status<>CWS_ConstantClass.ORDER_STATUS_PROCESSED && sObjNewOrder.Status==CWS_ConstantClass.ORDER_STATUS_PROCESSED){
                    sObjNewOrder.SBQQ__Contracted__c = True;
                }//BED:4997 Ends
            }
        } catch (Exception e) {
            CWS_ExceptionHandler.logException(e, 'Order' , 'CWS_OrderTriggerHelper','beforeUpdate' ,'', null, null ,'Before Update' , null);
        }
    }
	
	 /**
    * @Method: after update
    * @Developer: swachatterjee@deloitte.com
    * @Description: Trigger logic on After Update event of an Order
    * @Requirement/Issue: BED - 6945
     */
    public static void afterUpdate(Map<Id, SObject> newMap, Map<Id, SObject> oldMap){
        // Declare the collections
        Set<Id> setOrderIds = null;
        List<Order> lstOrdersToBeSubmitted = null;
         List<Order> lstOrders = new List<Order>();
         List<Id> quoteId = new List<Id>();
         List<Order> lstAllOrdersInSequence = null;
         Map<Id, Order> mapQuotetoOrder = new Map<Id,Order>();
        Set<Id> nonEvergreenOrder = new Set<Id>();
        Set<Id> evergreenOrder = new Set<Id>();
            
        try {
            // Instantiate the collections
            setOrderIds = new Set<Id>();
            lstOrdersToBeSubmitted = new List<Order>();
            lstAllOrdersInSequence = new List<Order>();
			// Iterate through the context variables
            for(Id idKey: newMap.keySet()){
                
                Order sObjNewOrder = (Order) newMap.get(idKey);
                Order sObjOldOrder = (Order) oldMap.get(idKey);
                
             
                // If the Service Provisioned checkbox is checked
                if(!sObjOldOrder.CWS_ServicesProvisioned__c && sObjNewOrder.CWS_ServicesProvisioned__c){
                    // Store it in the Set of Order Ids
                    setOrderIds.add(sObjNewOrder.id);
                }
                // BED - 1350 : START
                // Verify if the Order status changes to Ready for Submission
                // [All Validations fired since the event is after update]
                if(sObjOldOrder.Status <> CWS_ConstantClass.ORDER_STATUS_READY_FOR_SUBMISSION && 
                            sObjNewOrder.Status==CWS_ConstantClass.ORDER_STATUS_READY_FOR_SUBMISSION){
                    // Capture the order instances in a list of orders to be submissed             
                    lstOrdersToBeSubmitted.add(sObjNewOrder);
                    quoteId.add(sObjNewOrder.SBQQ__Quote__c);
                }
                // BED - 1350 : END
            }
            /* BED-12737 Start
            In case of Order Split, NE order has to be processed first, before we can Process the Evergreen Order
			Query the OrderItems and get the List of Evergreen Orders
         	*/ 
            for(OrderItem obj : [Select id, SBQQ__SubscriptionType__c, OrderId from OrderItem where orderId in: lstOrdersToBeSubmitted]){
                if(obj.SBQQ__SubscriptionType__c == CWS_ConstantClass.Subscription_Type_Evergreen ){
                    evergreenOrder.add(obj.OrderId);
                }else{
                    nonEvergreenOrder.add(obj.OrderId);
                }
            }
            
        	//Create a Map of Quote with the orders which are not yet processed
           for(Order obj : [Select id,SBQQ__Quote__c, OrderNumber, Status, CWS_Evergreen_Order__c, EndDate from Order where SBQQ__Quote__c in: quoteId]){
           		if(!newMap.keySet().contains(obj.id)){
           			mapQuotetoOrder.put(obj.SBQQ__Quote__c, obj);
                    System.debug('Map'+mapQuotetoOrder);
           	    }
           }
            
           for(Order obj: lstOrdersToBeSubmitted){
            	if(!evergreenOrder.contains(obj.id)){
            		if(mapQuotetoOrder.keySet().contains(obj.SBQQ__Quote__c) 
            						&& mapQuotetoOrder.get(obj.SBQQ__Quote__c).Status == CWS_ConstantClass.ORDER_STATUS_READY_FOR_SUBMISSION){
            			lstAllOrdersInSequence.add(obj);
            			lstAllOrdersInSequence.add(mapQuotetoOrder.get(obj.SBQQ__Quote__c));
                                    }else{
                                        lstAllOrdersInSequence.add(obj);
                                    }
            	}else{
            		if(mapQuotetoOrder.keySet().contains(obj.SBQQ__Quote__c) 
            						&& mapQuotetoOrder.get(obj.SBQQ__Quote__c).Status != CWS_ConstantClass.ORDER_STATUS_PROCESSED 
            											&& !mapQuotetoOrder.get(obj.SBQQ__Quote__c).CWS_Evergreen_Order__c ){
            			obj.addError('Please process the non-evergreen orders first under the same quote to process this one.');
            		}else{
            			lstAllOrdersInSequence.add(obj);
            		}
            	}
            }
            
           
            //List of Orders to be sent downstream for Processing
            //Passing the list of Orders to be arranged in a sequence - {NE, E}
            lstOrders = sequenceOrder(lstOrdersToBeSubmitted,evergreenOrder);
            //END BED-12737
            
            // Instantiate list of Order Items to be Updated
            List<OrderItem> lstOrderItems=new List<OrderItem>();
            if(!setOrderIds.isEmpty()){
                for(OrderItem sObjOrderItem: [select Id, CWS_ServicesProvisioned__c from OrderItem where OrderId in: setOrderIds and CWS_Provisioning_Eligibility__c<>:CWS_ConstantClass.PROVISIONAL_ELIGIBILITY_NA and CWS_ServicesProvisioned__c=false LIMIT 50000]){
                    sObjOrderItem.CWS_ServicesProvisioned__c=true;
                    lstOrderItems.add(sObjOrderItem);
                }
            }
			
			 List<Database.SaveResult> saveResults = null;
            if(!lstOrderItems.isEmpty()){
                // Invoke  DML
                saveResults = Database.update(lstOrderItems,true);
                // Log the save results for faulty orders
                CWS_ExceptionHandler.logDMLSaveResults(saveResults,'CWS_OrderItemHelper','afterUpdate','OrderItem','','CWS_OrderItemTrigger');
            }
            // BED - 1350 : Start
            // Invoke the Submit Order batch for prcessing the list of orders submitted
            // Batch frequnecy is 1. So that only one order processes at a time
            // the list of orders to be submitted is passed on as an argument
            if(!lstOrdersToBeSubmitted.isEmpty()){
                //Database.executeBatch(new CWS_SubmitOrderBatch(lstOrdersToBeSubmitted),CWS_ConstantClass.CALLOUT_BATCH_FREQUENCY);
                Database.executeBatch(new CWS_SubmitOrderBatch(lstOrders),lstOrders.size());
            }
            // BED - 1350 : END

        } catch (Exception e) {
            if(!lstOrdersToBeSubmitted.isEmpty()){
                 CWS_ExceptionHandler.logException(e, 'Order' , 'CWS_OrderTriggerHelper','afterUpdate' ,'', null, lstOrders[0].Id ,'After Update' , null);
             }else{
                 CWS_ExceptionHandler.logException(e, 'Order' , 'CWS_OrderTriggerHelper','afterUpdate' ,'', null, null,'After Update' , null);
             }
        }
    }

    /**
    * @Method: after insert
    * @Developer: swachatterjee@deloitte.com
    * @Description: Trigger logic on After Insert event of an Order
    * @Requirement/Issue: BED - 1350
     */
    public static void afterInsert(Map<Id, SObject> newItems) {
        List<Order> lstOrdersToBeSubmitted = null;
        List<Order> lstOrders = new List<Order>();
        Set<ID> evergreenOrder = new Set<Id>();
        Set<Id> nonEvergreenOrder = new Set<Id>();
        try {
            lstOrdersToBeSubmitted = new List<Order>();
            // Iterate through the new Items
            for(SObject sObj: newItems.values()){
                Order sObjNewOrder = (Order)sObj;
                // Verify if the order is in Ready for submission status
                if(sObjNewOrder.Status==CWS_ConstantClass.ORDER_STATUS_READY_FOR_SUBMISSION ){
                    lstOrdersToBeSubmitted.add(sObjNewOrder);
                }
            }
            for(OrderItem obj : [Select id, SBQQ__SubscriptionType__c, OrderId from OrderItem where orderId in: lstOrdersToBeSubmitted]){
                if(obj.SBQQ__SubscriptionType__c == CWS_ConstantClass.Subscription_Type_Evergreen){
                    evergreenOrder.add(obj.OrderId);
                }else{
                    nonEvergreenOrder.add(obj.OrderId);
                }
            }
       
            lstOrders = sequenceOrder(lstOrdersToBeSubmitted, evergreenOrder);
            System.debug('LInsert-'+lstOrders);
            // BED - 1350 : Start
            // Invoke the Submit Order batch for prcessing the list of orders submitted
            // Batch frequnecy is 1. So that only one order processes at a time
            // the list of orders to be submitted is passed on as an argument
            if(!lstOrdersToBeSubmitted.isEmpty()){
                //Database.executeBatch(new CWS_SubmitOrderBatch(lstOrdersToBeSubmitted),CWS_ConstantClass.CALLOUT_BATCH_FREQUENCY);
                Database.executeBatch(new CWS_SubmitOrderBatch(lstOrders),lstOrders.size());
            }
            // BED - 1350 : END

        } catch (Exception e) {            
            if(!lstOrdersToBeSubmitted.isEmpty()){
                 CWS_ExceptionHandler.logException(e, 'Order' , 'CWS_OrderTriggerHelper','afterUpdate' ,'', null, lstOrders[0].Id ,'After Update' , null);
             }else{
                 CWS_ExceptionHandler.logException(e, 'Order' , 'CWS_OrderTriggerHelper','afterUpdate' ,'', null, null,'After Update' , null);
             }
        }

    }

    
    /* Method name  : getTaxCompanyCode
    *  Parameter    : Order Record
    *  Return Type  : String
    *  Developer    : Chander
    *  User Story   : BED-5500
    */
    
    public static map<string,String> getTaxCompanyCode(){
        map<string,String>companycodeLEMap = new Map<string,string>();
        integer queryLimit = Integer.valueOf(Label.CWS_Custom_Metedata_Query_Limit);
        try{
        for( CWS_Currency_Legal_Entity_Mapping__mdt code : [select label,DeveloperName,CWS_Legal_Entity__c,CWS_Company_Code__c from CWS_Currency_Legal_Entity_Mapping__mdt LIMIT : Integer.valueOf(Label.CWS_Custom_Metedata_Query_Limit)])
            {
             companycodeLEMap.put(code.CWS_Legal_Entity__c,code.CWS_Company_Code__c);
            }
        }catch(Exception e) {
            CWS_ExceptionHandler.logException(e, 'Order' , 'CWS_OrderTriggerHelper','getTaxCompanyCode' ,'', null, null ,'getTaxCompanyCode' , null);
        }
        return companycodeLEMap;
    }

    /**
     * @Developer: Swachatterjee
     * @Description: Populate the address fields on Order
     */
    private static Order populateAddressDetails(Order sObjOrder,Map<Id,Account> mapAccounts){
        Account sObjBillingAccount = null;
        Account sObjShippingAccount = null;
        try {
            // Validate if the argument values are not valid
            if(sObjOrder<>null && mapAccounts<>null ){
                // Get the Bill to Account Id 
                Id idBillingAccount = sObjOrder.CWS_Bill_To_Account__c;
                if(idBillingAccount<>null && mapAccounts.containsKey(idBillingAccount)){
                    sObjBillingAccount = mapAccounts.get(idBillingAccount);
                }
                // Get the Ship to Account Id 
                Id idShippingAccount = sObjOrder.CWS_Ship_To_Account__c;
                if(idShippingAccount<>null && mapAccounts.containsKey(idShippingAccount)){
                    sObjShippingAccount = mapAccounts.get(idShippingAccount);
                }
            }
            // If the Billing account is populated on the order then extract the address 
            // fields from the same and populate as the billing address
            if(sObjBillingAccount<>null){
                sObjOrder.BillingCity = sObjBillingAccount.BillingCity;
                sObjOrder.BillingCountry = sObjBillingAccount.BillingCountry;
                sObjOrder.BillingCountryCode = sObjBillingAccount.BillingCountryCode;
                sObjOrder.BillingGeocodeAccuracy = sObjBillingAccount.BillingGeocodeAccuracy;
                sObjOrder.BillingLatitude = sObjBillingAccount.BillingLatitude;
                sObjOrder.BillingLongitude = sObjBillingAccount.BillingLongitude;
                sObjOrder.BillingPostalCode = sObjBillingAccount.BillingPostalCode;
                sObjOrder.BillingState = sObjBillingAccount.BillingState;
                sObjOrder.BillingStateCode = sObjBillingAccount.BillingStateCode;
                sObjOrder.BillingStreet = sObjBillingAccount.BillingStreet;
            }
            // If the Shipping account is populated on the order then extract the address 
            // fields from the same and populate as the billing address
            if(sObjShippingAccount<>null){
                sObjOrder.ShippingCity = sObjShippingAccount.BillingCity;
                sObjOrder.ShippingCountry = sObjShippingAccount.BillingCountry;
                sObjOrder.ShippingCountryCode = sObjShippingAccount.BillingCountryCode;
                sObjOrder.ShippingGeocodeAccuracy = sObjShippingAccount.BillingGeocodeAccuracy;
                sObjOrder.ShippingLatitude = sObjShippingAccount.BillingLatitude;
                sObjOrder.ShippingLongitude = sObjShippingAccount.BillingLongitude;
                sObjOrder.ShippingPostalCode = sObjShippingAccount.BillingPostalCode;
                sObjOrder.ShippingState = sObjShippingAccount.BillingState;
                sObjOrder.ShippingStateCode = sObjShippingAccount.BillingStateCode;
                sObjOrder.ShippingStreet = sObjShippingAccount.BillingStreet;
            }
        } catch(Exception e) {
            CWS_ExceptionHandler.logException(e, 'Order' , 'CWS_OrderTriggerHelper','populateAddressDetails' ,'', null, null ,'populateAddressDetails' , null);
        }
        return sObjOrder;
    }

     /**
    * @Method: beforeLegacyInsert
    * @Developer: swachatterjee@deloitte.com
    * @Description: Trigger logic on Before Insert event of an Order
     */
    public static void beforeLegacyInsert (List<SObject> lstNewOrders){
    	 Map<Id,SBQQ__Quote__c> mapQuotes = null;
    	  Set<Id> setRelatedQuoteIds = new Set<Id>();
        // BED-10670 START
        Map<String,String> mapLECompanyCodes = new Map<String,String>();
        try {
        	for(SObject sObj: lstNewOrders){
                Order sObjOrder = (Order)sObj;
                    setRelatedQuoteIds.add(sObjOrder.SBQQ__Quote__c);
            }
			mapQuotes = new Map<Id,SBQQ__Quote__c> ([select Id, SBQQ__StartDate__c,CWS_PO_Number__c
                                                        from SBQQ__Quote__c where Id in:setRelatedQuoteIds LIMIT 10000]);
            mapLECompanyCodes = getTaxCompanyCode();

            for(SObject sObj: lstNewOrders){
            	Order sObjOrder = (Order) sObj;
                Id idRelatedQuote = sObjOrder.SBQQ__Quote__c;
                SBQQ__Quote__c relatedQuoteObj = null;
                
                // Verify if the quote id is not blank on Order
                if(idRelatedQuote<>null && !String.isBlank(idRelatedQuote)&& mapQuotes<>null && mapQuotes.containsKey(idRelatedQuote)){
                  relatedQuoteObj = mapQuotes.get(idRelatedQuote);
                }
                sObjOrder.Status = CWS_ConstantClass.ORDER_STATUS_READY_FOR_SUBMISSION;
                sObjOrder.CWS_ServicesProvisioned__c = true;
                
                // Capture PO Number in a local variable
                String strPONumber = relatedQuoteObj.CWS_PO_Number__c;
                // If PO Number on QUote is available then populate on Order
                // Default the PO Number from Quote
                if(!String.isBlank(strPONumber)){
                    sObjOrder.PONumber = strPONumber;
                }
                // Populate the Company Code
                String strLegalEntity = sObjOrder.CWS_Legal_Entity__c;
                if(!String.isBlank(strLegalEntity) && mapLECompanyCodes<>null && mapLECompanyCodes.containsKey(strLegalEntity)) {
                    sObjOrder.CWS_Company_Code__c = mapLECompanyCodes.get(strLegalEntity);
                }
            }
        } catch (Exception e) {
            CWS_ExceptionHandler.logException(e, 'Order' , 'CWS_OrderTriggerHelper','beforeLegacyInsert' ,'', null, null ,'Before Insert' , null);
        }
        // BED-10670 END
    }

    /**
    * @Method: beforeLegacyUpdate
    * @Developer: swachatterjee@deloitte.com
    * @Description: Trigger logic on Before Update event of an Order
     */
    //Method not getting used anywhere- so commented
  /* public static void beforeLegacyUpdate(Map<Id, SObject> newMap, Map<Id, SObject> oldMap){
        try {
            // Iterate through the Orders to be updated
            for(Id idKey: newMap.keySet()){
                Order sObjNewOrder = (Order) newMap.get(idKey);
                Order sObjOldOrder = (Order) oldMap.get(idKey);
                
                //BED:4997 Starts
                if(sObjOldOrder.Status<>CWS_ConstantClass.ORDER_STATUS_PROCESSED && sObjNewOrder.Status==CWS_ConstantClass.ORDER_STATUS_PROCESSED){
                    sObjNewOrder.SBQQ__Contracted__c = True;
                }//BED:4997 Ends
            }
        } catch (Exception e) {
            CWS_ExceptionHandler.logException(e, 'Order' , 'CWS_OrderTriggerHelper','beforeUpdate' ,'', null, null ,'Before Update' , null);
        }
    }*/
	
	   /**
    * @Method: sequenceOrder
    * @Developer: agangeley@deloitte.com
    * @Description: Reusable method to Sequence the Orders, {NE;Evergreen}
     */ 
     //Optimisation needed
    public static List<Order> sequenceOrder(List<Order> lstAllOrdersInSequence, Set<id> evergreen){
    	List<Order> lstOrders = new List<Order>();
    	
        for(Order obj: lstAllOrdersInSequence){
            if(!evergreen.contains(obj.Id)){
                lstOrders.add(obj);
            }
        }
        for(Order obj: lstAllOrdersInSequence){
            if(evergreen.contains(obj.Id)){
                lstOrders.add(obj);
            }
        }
        return lstOrders;
    }
}