/*Class Name: CWS_CommonUtility	
*Description: Common Helper methods	
*Created By: Khayam	
*Created On: 4/13/2020	
*Modification Log	
*------------------------------------------------------------------------------------------	
*Developer              Date            Story               Description	
*------------------------------------------------------------------------------------------	
*Khayam                 4/13/2020                           Quote Stage sync with Quote Documents	
*Aakash                 5/18/2020                           Added two methods for Fast Track User Check and Mandatory Fields Check	
*Indra Ganesan          5/20/2020                           refreshPriceOnQuote	
*Megha Shetty           6/18/2020                           8913 Warning message for prior reneal cap%	
*Megha Shetty           6/30/2020                           5912 Error message for Special Manage product associated orders and subscriptions
*Carl Shahan            1/27/2021       #14154761           Changed reference to isProvisioningPending() lines 466 from CWS_QuoteDocumentTriggerHelper to CWS_QuoteDocumentTriggerUtility	
*/	
public with sharing class CWS_CommonUtility {	
    public static void sendEmail(String subject, String htmlBody, List<String> toAddresses){	
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();	
        message.toAddresses = toAddresses;	
        message.subject = subject;	
        message.htmlBody = htmlBody;	
        try{	
            Messaging.SingleEmailMessage[] messages =	
                new List<Messaging.SingleEmailMessage> {message};	
                    Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);	
            if (!results[0].success) {	
                CWS_ExceptionHandler.logErrors('CWS_CommonUtility', 'sendEmail' , '', results[0].errors[0].message, null, null, null);	
            }	
        } catch(Exception e){	
            CWS_ExceptionHandler.logException( e,'' , 'CWS_CommonUtility' , 'sendEmail' ,'', null , null ,'sendEmail' , null);	
        }	
    }	
    public static void sendOFCancellationEmail(List<SBQQ__QuoteDocument__c> qDocs){	
        try{	
            EmailTemplate et = [SELECT Id,Subject, Body FROM EmailTemplate WHERE DeveloperName =: CWS_ConstantClass.QUOTE_OF_NOTIF_TEMPLATE];	
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();	
            for (SBQQ__QuoteDocument__c qDoc : qDocs) {	
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();	
                message.setTemplateId(et.id);	
                message.setTargetObjectId(qDoc.SBQQ__PrimaryContactId__c);	
                message.toAddresses = new String[] {qDoc.SBQQ__PrimaryContactId__c,qDoc.SBQQ__Quote__r.OwnerId};	
                    message.setWhatId(qDoc.SBQQ__Quote__c);	
                message.setSaveAsActivity(true);	
                messages.add(message);	
            }	
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);	
            if (!results[0].success) {	
                CWS_ExceptionHandler.logErrors('CWS_CommonUtility', 'sendOFCancellationEmail' , '', results[0].errors[0].message, null, null, null);	
            }	
        } catch(Exception e){	
            CWS_ExceptionHandler.logException( e,'' , 'CWS_CommonUtility' , 'sendOFCancellationEmail' ,'', null , null ,'sendOFCancellationEmail' , null);	
        }	
    }	
    // Added to resolve error - BED-10636 Account manager is not able to clone the Renewal quote.	
    @future	
    public static void updateRenewalWCQuoteOwner(Set<Id> quoteIDs ){	
        try{	
            List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();	
            if( quoteIDs != null && !quoteIDs.isEmpty()){	
                Map<Id,SBQQ__Quote__c> quoteMap= new Map<Id,SBQQ__Quote__c>([SELECT	
                                                                             id,	
                                                                             CWS_Quote_Type__c,	
                                                                             ownerId,	
                                                                             SBQQ__Opportunity2__r.ownerid	
                                                                             FROM SBQQ__Quote__C	
                                                                             WHERE Id in :quoteIds]);	
                for (SBQQ__Quote__c quote : quoteMap.values()) {	
                    if(quote.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC && quote.ownerId !=  quote.SBQQ__Opportunity2__r.ownerid ){	
                        quote.ownerId = quote.SBQQ__Opportunity2__r.ownerid;	
                        quotesToUpdate.add(quote);	
                    }	
                }	
            }	
            if(quotesToUpdate!= null && !quotesToUpdate.isEmpty()){	
                update quotesToUpdate;	
            }	
        }catch(Exception e){	
            CWS_ExceptionHandler.logException( e,'' , 'CWS_CommonUtility' , 'updateRenewalWCQuoteOwner' ,'', null , null ,'updateRenewalWCQuoteOwner' , null);	
        }	
    }	
    /*	
Method Name : CAUserCheck	
* Description : Added to check for  the Fast Track Quote Public group and Contract Admin Public Group	
* Returns     : Boolean	
* Developer   : Aakash	
*/	
    @AuraEnabled	
    public static List<String> CAUserCheck(Id QuoteId){	
        Id loggedUser=userInfo.getUserId();	
        boolean BolUserCheck=false;	
        String strGroupFT = CWS_ConstantClass.GroupnameFTQ;	
        String strGroupCA = CWS_ConstantClass.GroupnameCA;	
        SBQQ__Quote__c QuoteObj;	
        List<SBQQ__QuoteLine__c> lstquoteLn = new List<SBQQ__QuoteLine__c>();	
        List<Group> LstPGroups = new List<Group>();	
        Map<id,string> mapUserFT = new Map<id,string>();	
        Map<id,string> mapUserCA = new Map<id,string>();	
        Map<id,string> mapUserRegion = new Map<id,string>();	
        List<String> LstErrors = new List<String>();	
        Integer intLimit=Integer.valueOf(Label.CWS_Custom_Metedata_Query_Limit);	
        intLimit=intLimit+3500;	
        String RenewalType;	
        String strGroupRegion;	
        //BED-6506	
        Decimal CancelCount=0;	
        Boolean CancelQuote=false;	
        //BED-6506	
        try{	
            User userObj=new User();	
            if(QuoteId != null){	
                QuoteObj=[select id,CWS_isFastTrack__c, CWS_Quote_Type__c, SBQQ__Primary__c,SBQQ__Status__c,SBQQ__Account__c,SBQQ__Account__r.CWS_AgreementStatus__c,CWS_Renewal_Category__c,CWS_Sub_Stage__c,CWS_Transaction_Reason__c, CWS_Sub_Type__c, ApprovalStatus__c, CWS_Region__c,SBQQ__LineItemCount__c from SBQQ__Quote__c where id =: QuoteId];	
                //added as part of BED-6434	
                lstquoteLn = [SELECT id, CWS_Renewal_Type__c,CWS_Transaction_Type__c,SBQQ__SubscriptionType__c,SBQQ__Product__c,SBQQ__Product__r.CWS_Base_SKU__c,SBQQ__Quote__r.CWS_Master__c from SBQQ__QuoteLine__c where  SBQQ__Quote__c =: QuoteId];	
                //end of BED-6434	
            }	
            //start of BED-6434	
            if(!lstquoteLn.isEmpty()){	
                for(SBQQ__QuoteLine__c qLine : lstquoteLn){	
                    //BED-12497	
                    if(qline.SBQQ__SubscriptionType__c!= CWS_ConstantClass.Subscription_Type_Evergreen){	
                        if(qLine.CWS_Renewal_Type__c != null && String.isNotEmpty(RenewalType)){	
                            if(RenewalType!=qLine.CWS_Renewal_Type__c){	
                                RenewalType = CWS_ConstantClass.Renewal_Category_SplitPending;	
                            }	
                        }	
                        else if(qLine.CWS_Renewal_Type__c != null){	
                            RenewalType = qLine.CWS_Renewal_Type__c;	
                        }	
                    }	
                    //BED-12497	
                    //BED-6506	
                    //BED-12642 : Added the baseSKU 900901 && 900904 to be added as cancel	
                    if(qLine.CWS_Transaction_Type__c == 'Cancel' || (qLine.SBQQ__Quote__r.CWS_Master__c == true && (	
                        qLine.SBQQ__Product__r.CWS_Base_SKU__c == CWS_ConstantClass.MINCOM_BASESKU_900901 ||	
                        qLine.SBQQ__Product__r.CWS_Base_SKU__c == CWS_ConstantClass.MINCOM_BASESKU_900904))){	
                            CancelCount+=1;	
                        }	
                }	
                if(CancelCount == QuoteObj.SBQQ__LineItemCount__c)	
                {	
                    CancelQuote=true;	
                }	
                //BED-6506	
            }	
            //End of BED-6434	
            if(QuoteObj.CWS_Region__c !=null){	
                if(QuoteObj.CWS_Region__c == 'APAC'){	
                    strGroupRegion = CWS_ConstantClass.APAC_Region;	
                }	
                else if(QuoteObj.CWS_Region__c == 'EMEA/ROW'){	
                    strGroupRegion = CWS_ConstantClass.UK_EMEA_Region;	
                }	
                else{	
                    strGroupRegion = CWS_ConstantClass.NA_Region;	
                }	
            }	
            if(loggedUser != null){	
                userObj=[select id,Profile.Name from user where id=:loggedUser];	
            }	
            if(strGroupFT != null && strGroupCA != null && intLimit != null && strGroupRegion != null){	
                LstPGroups=[select id,name,DeveloperName,(Select id,UserOrGroupId from GroupMembers LIMIT : intLimit) from Group where DeveloperName =:strGroupFT OR DeveloperName =:strGroupCA or DeveloperName =:strGroupRegion];	
            }	
            else if(strGroupFT != null && strGroupCA != null && intLimit != null){	
                LstPGroups=[select id,name,DeveloperName,(Select id,UserOrGroupId from GroupMembers LIMIT : intLimit) from Group where DeveloperName =:strGroupFT OR DeveloperName =:strGroupCA];	
            }	
            for(Group grp : LstPGroups){	
                if(grp.DeveloperName == strGroupFT){	
                    for(GroupMember members:grp.GroupMembers)	
                    {	
                        mapUserFT.put(members.UserOrGroupId,grp.DeveloperName);	
                    }	
                }	
                else if(grp.DeveloperName == strGroupCA){	
                    for(GroupMember members:grp.GroupMembers)	
                    {	
                        mapUserCA.put(members.UserOrGroupId,grp.DeveloperName);	
                    }	
                }	
                if(grp.DeveloperName == strGroupRegion){	
                    for(GroupMember members:grp.GroupMembers)	
                    {	
                        mapUserRegion.put(members.UserOrGroupId,grp.DeveloperName);	
                    }	
                }	
            }	
            //start of BEd-6434	
            if(String.isNotEmpty(RenewalType) && QuoteId != null){	
                QuoteObj.CWS_Renewal_Category__c = RenewalType;	
                update QuoteObj;	
            }	
            //End of BED-6434	
            /*if(userObj!=null && ((mapUserFT!=null && (mapUserFT.containskey(userObj.id) || userObj.Profile.name == CWS_ConstantClass.SysAdminProfile) && QuoteObj.CWS_isFastTrack__c)||(mapUserCA != null && (mapUserCA.containskey(userObj.id) || userObj.Profile.name == CWS_ConstantClass.SysAdminProfile) && QuoteObj.SBQQ__Status__c == 'Awaiting Signature'))){	
BolUserCheck=true;	
}	
*/	
            //BED-6506	
            Boolean isAmendmentSkip = (QuoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT	
                                       &&	
                                       (QuoteObj.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_ORDERFORM_GEN ||(QuoteObj.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_APPROVED && QuoteObj.ApprovalStatus__c == CWS_ConstantClass.QUOTE_Approval_Status_Approved) || QuoteObj.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_AWAIT_SIG)	
                                       &&	
                                       ((QuoteObj.CWS_Transaction_Reason__c == CWS_ConstantClass.TRANSACTION_REASON_MERGER_ACQUISTION && CancelQuote) || (QuoteObj.CWS_Transaction_Reason__c == CWS_ConstantClass.TRANSACTION_REASON_RECOMMIT && CancelQuote) || (QuoteObj.CWS_Transaction_Reason__c == CWS_ConstantClass.TRANSACTION_REASON_CREDIT_REBILL && QuoteObj.CWS_Sub_Type__c == CWS_ConstantClass.QUOTE_SUB_TYPE_CREDIT && CancelQuote)|| QuoteObj.CWS_Transaction_Reason__c == CWS_ConstantClass.TRANSACTION_REASON_TERMINATION));	
            //BED-6506	
            Boolean isPendingFull = (userObj.Profile.name == 'CWS_Order_Management' && quoteObj.CWS_Sub_Stage__c == CWS_ConstantClass.ORDER_STATUS_PENDING_FULFILLMENT);	
            //BED-13052	
            if(!(mapUserRegion.containsKey(userObj.Id) && isAmendmentSkip)){	
                if(!isPendingFull && QuoteObj.CWS_isFastTrack__c && QuoteObj.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_DRAFT && (!mapUserFT.containskey(userObj.id) && userObj.Profile.name != CWS_ConstantClass.SysAdminProfile)){	
                    LstErrors.add('Please contact your Contract Admin Team to Move this Fast Track Quote to Accepted.');	
                }	
                if(!isPendingFull && !QuoteObj.CWS_isFastTrack__c && QuoteObj.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_AWAIT_SIG && (!mapUserCA.containskey(userObj.id) && (userObj.Profile.name != CWS_ConstantClass.ContractAdminProfile && userObj.Profile.name != CWS_ConstantClass.SysAdminProfile && !(userObj.Profile.name == CWS_ConstantClass.GlobalSalesOpsProfile && QuoteObj.CWS_Transaction_Reason__c == CWS_ConstantClass.TRANSACTION_AGREEMENT_CONVERSION && quoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS)))){	
                    if(QuoteObj.CWS_Transaction_Reason__c == CWS_ConstantClass.TRANSACTION_AGREEMENT_CONVERSION && quoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS){	
                        LstErrors.add('Please reach out to Order Management team to accept this quote since its Transaction Reason is "Agreement Conversion"');	
                    }	
                    else{	
                        LstErrors.add('Please contact your Contract Admin Team to move this Quote to Accepted.');	
                    }	
                }	
                //BED-13052	
            }	
            //bed-8851 starts	
            if(((QuoteObj.CWS_isFastTrack__c && (QuoteObj.SBQQ__Status__c != CWS_ConstantClass.QUOTE_STATUS_DRAFT && QuoteObj.SBQQ__Status__c != CWS_ConstantClass.QUOTE_STATUS_REVISION)) || !QuoteObj.CWS_isFastTrack__c) && QuoteObj.SBQQ__Status__c != CWS_ConstantClass.QUOTE_STATUS_AWAIT_SIG	
               && !isAmendmentSkip){	
                   //BED-12642 & BED-12644	
                   if(!QuoteObj.SBQQ__Primary__c){	
                       LstErrors.add(System.label.CWS_NonPrimaryQuoteErrMsgOnFTQuote); //BED-12644	
                   } else if(QuoteObj.CWS_Transaction_Reason__c == CWS_ConstantClass.TRANSACTION_REASON_RECOMMIT && CancelQuote){	
                       LstErrors.add(System.label.CWS_RecommitErrMsgOnFTQuote); //BED-12642	
                   } else{	
                       LstErrors.add('You Cannot Accept the Quote.');	
                   }	
               }	
            //bed-8851 ends	
            return LstErrors;	
        }catch(Exception e){	
            CWS_ExceptionHandler.logException( e,'Quote' , 'CWS_CommonUtility', 'CAUserCheck' , '', null, null , 'CWS_CommonUtility' , null);	
            throw new AuraHandledException('Exception occurred while Running this class : '+ e.getMessage());	
        }	
    }	
    /* Method Name : fieldsChk	
* Description : Added for the mandatory Field that needs to be present at the Quote level	
* Returns     : List<String>	
* Developer   : Aakash	
*/	
    @AuraEnabled	
    public static List<String> fieldsChk(String quoteId, Boolean isContinue){	
        Boolean costError = false;	
        List<String> lstErrors=new List<String>();	
        //5912 start	
        List<OrderItem> lstordersproducts = new List<OrderItem>();	
        integer totalQTY=0;	
        integer priorTotalQTY=0;	
        integer totalPriorQTYForAmmend = 0;	
        integer totalPriorQTYForRWC = 0;	
        Boolean checksplManage = false;	
        Boolean EvergreenLinePresent = false;	
        Boolean PrimarySTA=false;	
        Boolean PrimaryBTA=false;	
        Set<id> setAccoundID = new set<id>();	
        //5912 end	
        Id loggedUser=userInfo.getUserId();	
        User userObj=new User();	
        if(loggedUser != null){	
            userObj=[select id,Profile.Name from user where id=:loggedUser];	
        }	
        SBQQ__Quote__c QuoteObj=[select id,CWS_isFastTrack__c,CWS_Renewal_CAP__c,CWS_Prior_Renewal_CAP__c,CWS_Quote_Type__c,CWS_Bill_To_Account__c,CWS_Bill_To_Contact__c,CWS_Sub_Stage__c,	
                                 CWS_Master__c,SBQQ__StartDate__c, SBQQ__EndDate__c,CWS_Addendum_Number__c, CWS_Original_Contract__c, CWS_Credit_Quote__c,	
                                 CWS_Ship_To_Account__c,CWS_Ship_To_Contact__c,CWS_Renewal_Type__c,CWS_Quote_ACV__c,SBQQ__Account__c, CWS_Transaction_Reason__c, CWS_Sub_Type__c,	
                                 SBQQ__PrimaryContact__c,SBQQ__PaymentTerms__c,CWS_Legal_Entity__c,SBQQ__Opportunity2__c,SBQQ__LineItemCount__c, ApprovalStatus__c,	
                                 SBQQ__Primary__c,SBQQ__Status__c,SBQQ__Account__r.CWS_MSA_Agreement__c,SBQQ__Account__r.CWS_NDA_Agreement__c,	
                                 SBQQ__Account__r.CWS_BA_Agreement_Status__c ,SBQQ__Account__r.CWS_MSA_Agreement_Status__c,SBQQ__Account__r.CWS_NDA_Agreement_Status__c,	
                                 SBQQ__Account__r.CWS_BA_Agreement__c,SBQQ__ExpirationDate__c,CWS_Vendor_Approval_Received__c,CWS_OF_Signed_Override_Date__c,	
                                 CWS_Master_Dedicated_Tech__c,SBQQ__PrimaryContact__r.CWS_Primary_Billing_Contact__c,SBQQ__PrimaryContact__r.CWS_Primary_Contact__c,CWS_Pre_payment_Amount__c,CWS_Bill_To_Account__r.id,SBQQ__Account__r.id from SBQQ__Quote__c where id=:quoteId];	
        List<SBQQ__QuoteLine__c> quoteLine = [Select Id,CWS_Subscription_Quantity__c,SBQQ__PriorQuantity__c,SBQQ__Quantity__c,CWS_Manage_Special_Product__c,CWS_Manage_Product__c, CWS_Cost_Price__c, CWS_Original_Cost_Price__c,SBQQ__SubscriptionType__c from SBQQ__QuoteLine__c where SBQQ__Quote__c =:quoteId];	
        //BED-13423	
        if(QuoteObj.CWS_Bill_To_Account__c!=null && QuoteObj.SBQQ__Account__c !=null && QuoteObj.CWS_Bill_To_Account__c == QuoteObj.SBQQ__Account__c){	
            setAccoundID.add(QuoteObj.CWS_Bill_To_Account__r.id);	
        }	
        if(QuoteObj.CWS_Bill_To_Account__c!= null && QuoteObj.SBQQ__Account__c != null &&  QuoteObj.CWS_Bill_To_Account__c != QuoteObj.SBQQ__Account__c){	
            setAccoundID.add(QuoteObj.CWS_Bill_To_Account__r.id);	
            setAccoundID.add(QuoteObj.SBQQ__Account__r.id);	
        }	
        system.debug(setAccoundID);	
        list<Contact> lstcontact=[select id,AccountId,CWS_Primary_Billing_Contact__c,CWS_Primary_Contact__c from contact where AccountId in:setAccoundID and (CWS_Primary_Billing_Contact__c=true OR CWS_Primary_Contact__c=true)];	
        if(!lstcontact.isEmpty()){	
            for(Contact Cont:lstcontact){	
                if(QuoteObj.CWS_Bill_To_Account__c !=null && QuoteObj.SBQQ__Account__c != null &&  QuoteObj.CWS_Bill_To_Account__c == QuoteObj.SBQQ__Account__c){	
                    if(Cont.CWS_Primary_Contact__c || Cont.CWS_Primary_Billing_Contact__c)	
                    {	
                        PrimarySTA=true;	
                        PrimaryBTA=true;	
                    }	
                }	
                else{	
                    if(Cont.AccountId == QuoteObj.SBQQ__Account__r.id)	
                    {	
                        if(Cont.CWS_Primary_Contact__c || Cont.CWS_Primary_Billing_Contact__c)	
                        {	
                            PrimarySTA=true;	
                        }	
                    }	
                    else	
                    {	
                        if(Cont.CWS_Primary_Contact__c  || cont.CWS_Primary_Billing_Contact__c)	
                        {	
                            PrimaryBTA=true;	
                        }	
                    }	
                }	
            }	
        }	
        //BED-13423	
        for(SBQQ__QuoteLine__c qLine: quoteLine){	
            if(qLine.CWS_Cost_Price__c!=qLine.CWS_Original_Cost_Price__c){	
                costError=true;	
            }	
            //5912 starts	
            if (qLine.CWS_Manage_Special_Product__c == true )	
            {   if(qLine.SBQQ__Quantity__c!=0)	
                checksplManage= true;	
             totalQTY += (qLine.SBQQ__Quantity__c).intValue();	
             if(quoteObj.CWS_Quote_Type__c == CWS_ConstantClass.Quote_Type_Amendment && qLine.SBQQ__PriorQuantity__c!= null )	
             {	
                 totalPriorQTYForAmmend += (qLine.SBQQ__PriorQuantity__c).intValue();	
             }	
             if(quoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC && qLine.CWS_Subscription_Quantity__c!= null)	
             {	
                 totalPriorQTYForRWC += (qLine.CWS_Subscription_Quantity__c).intValue();	
             }	
            }	
            if(qLine.CWS_Manage_Product__c == true )	
            {   totalQTY += (qLine.SBQQ__Quantity__c).intValue();	
             if(quoteObj.CWS_Quote_Type__c == CWS_ConstantClass.Quote_Type_Amendment && qLine.SBQQ__PriorQuantity__c!= null )	
             {	
                 totalPriorQTYForAmmend += (qLine.SBQQ__PriorQuantity__c).intValue();	
             }	
             if(quoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC && qLine.CWS_Subscription_Quantity__c!= null)	
             {	
                 totalPriorQTYForRWC += (qLine.CWS_Subscription_Quantity__c).intValue();	
             }	
            }	
            //5912 end	
            //BED-13237	
            if(qline.SBQQ__SubscriptionType__c == CWS_ConstantClass.Subscription_Type_Evergreen && !EvergreenLinePresent){	
                EvergreenLinePresent=true;	
            }	
            //BED-13237	
        }	
        //5912 starts	
        if(checksplManage == true && totalQTY < 2 && totalQTY!= 0 )	
        {	
            ID soldToAccount = QuoteObj.SBQQ__Account__c;	
            lstordersproducts =[SELECT id,SBQQ__OrderedQuantity__c, Product2.CWS_Manage_Special_Product__c, Product2.CWS_Manage_Product__c from OrderItem where (Order.AccountId = :soldToAccount and (Product2.CWS_Manage_Product__c=true or Product2.CWS_Manage_Special_Product__c = true)) ];	
            if(lstordersproducts!= null)	
                for(OrderItem orderProducts : lstordersproducts){	
                    if(orderProducts.Product2.CWS_Manage_Special_Product__c == true && orderProducts.SBQQ__OrderedQuantity__c!= 0)	
                        priorTotalQTY += (orderProducts.SBQQ__OrderedQuantity__c).intValue();	
                    if(orderProducts.Product2.CWS_Manage_Product__c == true && orderProducts.SBQQ__OrderedQuantity__c!= 0)	
                        priorTotalQTY += (orderProducts.SBQQ__OrderedQuantity__c).intValue();	
                }	
            if(quoteObj.CWS_Quote_Type__c == CWS_ConstantClass.Quote_Type_Amendment ){	
                priorTotalQTY -= totalPriorQTYForAmmend;	
            }	
            if(quoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC ){	
                priorTotalQTY -= totalPriorQTYForRWC;	
            }	
            /**	
if((totalQTY + priorTotalQTY) <2 )	
{	
lstErrors.add(System.Label.CWS_SpecialManageProductError);	
}	
*/	
        }	
        //5912 ends	
        if(quoteObj.CWS_Master__c==true && quoteObj.CWS_Master_Dedicated_Tech__c==FALSE && !(QuoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT && QuoteObj.CWS_Transaction_Reason__c == CWS_ConstantClass.TRANSACTION_REASON_RECOMMIT)){	
            lstErrors.addAll(validateMinCommit(quoteObj));	
        }	
        //8913 starts	
        if(!isContinue && QuoteObj.CWS_Renewal_CAP__c == null && (QuoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC ||  QuoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS)){	
            lstErrors.add(System.label.CWS_Warning + System.Label.CWS_PriorRenewalCapBlankAlert);	
        }	
        //8913 ends	
        if(QuoteObj.CWS_Bill_To_Account__c == null){	
            lstErrors.add('Please Populate the Bill To Account ');	
        }	
        if(QuoteObj.CWS_Bill_To_Contact__c == null){	
            lstErrors.add('Please Populate the Bill To Contact');	
        }	
        if(QuoteObj.CWS_Ship_To_Account__c == null){	
            lstErrors.add('Please Populate the Ship To Account');	
        }	
        //START CR_RECOMMIT  For NB & RWC quotes if transaction reason is recommit and original contract and credit quote field is not populated then error is thrown	
        if(quoteObj.CWS_Transaction_Reason__c == CWS_ConstantClass.TRANSACTION_REASON_RECOMMIT  && (quoteObj.CWS_Original_Contract__c == null || quoteObj.CWS_Credit_Quote__c == null) &&	
           (quoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS || quoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWALWC)){	
               lstErrors.add(System.Label.CWS_Recommit_Contract_Error);	
           }	
        //END CR_RECOMMIT	
        //BED-13423	
        if(!PrimaryBTA){	
            lstErrors.add(System.Label.CWS_ErrorMessageBTAPrimary);	
        }	
        if(!PrimarySTA){	
            lstErrors.add(System.Label.CWS_ErrorMessageSTAPrimary);	
        }	
        //BED-13423	
        /*	
BED-4970	
if(QuoteObj.CWS_Ship_To_Contact__c == null){	
lstErrors.add('Please Populate the Ship To Contact');	
}	
*/	
        //RENEWALCAT_CHANGE_REQ - commenting this out as deactivating Opt-In/Opt-Out value	
        /*if(QuoteObj.CWS_Renewal_Type__c == null){	
lstErrors.add('Please Populate the Renewal Type');	
}*/	
        if(QuoteObj.CWS_Quote_ACV__c == null){	
            lstErrors.add('Quote ACV is Blank');	
        }	
        if(QuoteObj.SBQQ__Account__c == null){	
            lstErrors.add('Please Populate the Sold To Account.');	
        }	
        if(QuoteObj.SBQQ__PrimaryContact__c == null){	
            lstErrors.add('Please Populate the Primary Contact.');	
        }	
        if(QuoteObj.SBQQ__PaymentTerms__c == null){	
            lstErrors.add('Please Populate the Payment Terms.');	
        }	
        if(QuoteObj.CWS_Legal_Entity__c == null){	
            lstErrors.add('Please Populate the Legal Entity.');	
        }	
        if(QuoteObj.SBQQ__Opportunity2__c == null){	
            lstErrors.add('Please Populate the Opportunity.');	
        }	
        if(QuoteObj.SBQQ__LineItemCount__c == 0){	
            lstErrors.add('No Products are Added in the Quote.');	
        }	
        if(!QuoteObj.SBQQ__Primary__c){	
            lstErrors.add('Only primary quotes can be moved to Accepted stage. Please make quote as primary before accepting the quote.');	
        }	
        //BED-3204 //START CR_RECOMMIT  Adding termination condn	
        if(QuoteObj.CWS_Master__c && QuoteObj.CWS_Addendum_Number__c == NULL && QuoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT && QuoteObj.CWS_Transaction_Reason__c != CWS_ConstantClass.TRANSACTION_REASON_TERMINATION)	
        {	
            lstErrors.add('Please Populate the Addendum Number');	
        }	
        //BED-3204 //END CR_RECOMMIT	
        //BED-13052	
        if(QuoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS && QuoteObj.CWS_Transaction_Reason__c == CWS_ConstantClass.TRANSACTION_AGREEMENT_CONVERSION && QuoteObj.CWS_OF_Signed_Override_Date__c == NULL)	
        {	
            lstErrors.add('Please populate ‘OF Signed Override Date’ with the start date for Sales Contract before accepting the quote');	
        }	
        //BED-13052	
        //BED-13052	
        if(QuoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS && QuoteObj.CWS_Transaction_Reason__c == CWS_ConstantClass.TRANSACTION_AGREEMENT_CONVERSION && userObj != NULL && (userObj.Profile.name != CWS_ConstantClass.SysAdminProfile && userObj.Profile.Name != CWS_ConstantClass.ContractAdminProfile && userObj.Profile.name != CWS_ConstantClass.OMProfile && userObj.Profile.name != CWS_ConstantClass.GlobalSalesOpsProfile))	
        {	
            lstErrors.add('Please reach out to Order Management team to accept this quote since its Transaction Reason is "Agreement Conversion"');	
        }	
        //BED-13052	
        //BED-13237	
        if(EvergreenLinePresent && QuoteObj.CWS_Pre_payment_Amount__c > 0){	
            LstErrors.add(System.label.CWS_PrePaymentAmountErrorMessage);	
        }	
        //BED-13237	
        if((QuoteObj.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_DRAFT || QuoteObj.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_REVISION) && refreshPriceOnQuote(QuoteObj.id))	
        {	
            lstErrors.add('Price of the products has been updated, use Refresh Price button to refresh the Price.');	
        }
        // Ticket 14154761 Created seperate CWS_QuoteDocumentTriggerUtility class to reduce the complexity of the CWS_QuoteDocumentTriggerHelper class	
        if(!CWS_QuoteDocumentTriggerUtility.quoteAgreementInEffect(QuoteObj)){	
            lstErrors.add('All the open CLM agreements need to be closed to move this quote to Accepted.');	
        }	
        if(!QuoteObj.CWS_Vendor_Approval_Received__c && costError){	
            lstErrors.add('Since the 3rd party Cost has been adjusted, to proceed, please attach approvals received from 3rd party vendors and indicate step completion by selecting Vendor Approval Received.');	
        }	
        //Start BED-12710	
        //if(QuoteObj.SBQQ__PrimaryContact__c!= null && quoteObj.SBQQ__PrimaryContact__r.CWS_Primary_Contact__c!= true && quoteObj.SBQQ__PrimaryContact__r.CWS_Primary_Billing_Contact__c != true){	
        //lstErrors.add(System.Label.CWS_populate_primary_sol_to_contact);	
        //}	
        //END BED-12710	
        //bED-8851 starts	
        if(lstErrors.isEmpty() && (QuoteObj.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_DRAFT || QuoteObj.SBQQ__Status__c == 'Awaiting Signature'	
                                   || QuoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_AMENDMENT || QuoteObj.SBQQ__Status__c == CWS_ConstantClass.QUOTE_STATUS_REVISION ))	
        {//bed-8851 ends	
            try{	
                //BED-13502	
                if(QuoteObj.CWS_OF_Signed_Override_Date__c == null && !(QuoteObj.CWS_Transaction_Reason__c == CWS_ConstantClass.TRANSACTION_AGREEMENT_CONVERSION && quoteObj.CWS_Quote_Type__c == CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS)){	
                    QuoteObj.CWS_OF_Signed_Override_Date__c=Date.today();	
                }	
                //BED-13502	
                QuoteObj.SBQQ__Status__c=CWS_ConstantClass.QUOTE_STATUS_ACCEPTED;	
                QuoteObj.CWS_Sub_Stage__c=CWS_ConstantClass.QUOTE_STATUS_ACCEPTED;	
                Database.SaveResult SR = Database.update(QuoteObj);	
            } catch (System.DmlException e) {	
                String msg = '';	
                for (Integer i = 0; i < e.getNumDml(); i++) {	
                    System.debug(msg+=' '+e.getDmlMessage(i));	
                }	
                throw new AuraHandledException(msg);	
            }	
            catch(exception e){	
                CWS_ExceptionHandler.logException( e,'Quote' , 'MandatoryFieldsCheck', 'MandatoryFieldsCheck' , '', null, null , 'MandatoryFieldsCheck' , null);	
                throw new AuraHandledException(e.getMessage()+ 'Record ID'+e.getDMLId(0));                }	
        }	
        return lstErrors;	
    }	
    /* Method Name : getGroupMemberRegion	
* Description :  Method will parse the Account Manager Groups and Send Set of Regions for specific user Ids.	
* Returns     : Map<Id,Set<String>>	
* Developer   : Abhishek Shukla	
*/	
    public static Map<Id,Set<String>> getGroupMemberRegion(List<Id> userIds){	
        Map<String, String> mapRegionGroup = new Map<String, String>();	
        Map<Id, Set<String>> mapUserRegion = new Map<Id, Set<String>>();	
        if(userIds.size()>0){	
            for(CWS_RegionGroupMapping__mdt RegionGroup:[Select id,CWS_Region__c,	
                                                         CWS_GroupName__c	
                                                         from CWS_RegionGroupMapping__mdt	
                                                         Limit : Integer.valueOf(Label.CWS_Custom_Metedata_Query_Limit)]){	
                                                             mapRegionGroup.put(RegionGroup.CWS_GroupName__c,RegionGroup.CWS_Region__c);	
                                                         }	
            if(mapRegionGroup.keySet().size()>0){	
                for(Group grp:[select id,name,DeveloperName,	
                               (Select id,UserOrGroupId from GroupMembers where UserOrGroupId IN :userIds )	
                               from Group where DeveloperName =:mapRegionGroup.keySet()]){	
                                   for(GroupMember members:grp.GroupMembers){	
                                       if(mapUserRegion.get(members.UserOrGroupId)== Null){	
                                           mapUserRegion.put(members.UserOrGroupId,new Set<String>{mapRegionGroup.get(grp.DeveloperName)});	
                                       }else{	
                                           mapUserRegion.get(members.UserOrGroupId).add(mapRegionGroup.get(grp.DeveloperName));	
                                       }	
                                   }	
                               }	
            }	
        }	
        return mapUserRegion;	
    }	
    /* Method Name : refreshPriceOnQuote	
* Description : Warning Message is displayed on the page when there is a List price mismatch on Quoteline with that of PB associated with Quote Line	
* Returns     : Boolean	
* Developer   : Indra Ganesan	
*/	
    @AuraEnabled	
    public static Boolean refreshPriceOnQuote(Id QuoteId){	
        List<SBQQ__QuoteLine__c> lstquoteLn = new List<SBQQ__QuoteLine__c>();	
        set<id> pbeid = new set<id>();	
        boolean setError = false;	
        Map<Id, Double> mapPbToPrice = new Map<Id, Double>();	
        set<String> status = new set<String>();	
        set<String> QType = new set<String>();	
        Map<Id, Double> mapBlockPrice = new Map<Id, Double>();	
        List<SBQQ__BlockPrice__c> blockPrice = new List<SBQQ__BlockPrice__c>();	
        status.add(CWS_ConstantClass.QUOTE_STATUS_ACCEPTED);	
        status.add(CWS_ConstantClass.QUOTE_STATUS_INACTIVE);	
        QType.add(CWS_ConstantClass.QUOTE_TYPE_NEW_BUSINESS);	
        try{	
            if(quoteId != null){	
                List<SBQQ__Quote__c> lstquoteObj = [SELECT Id,CWS_Quote_Type__c,SBQQ__Status__c FROM SBQQ__Quote__c where id  = :quoteId AND SBQQ__Status__c NOT IN:status AND CWS_Quote_Type__c IN:QType LIMIT 1];	
                SBQQ__Quote__c quoteObj;	
                if(!lstquoteObj.isEmpty()){	
                    quoteObj=lstquoteObj[0];	
                }	
                if(quoteObj !=null && quoteObj.id != null) {	
                    lstquoteLn = [SELECT id, SBQQ__ListPrice__c, SBQQ__PricebookEntryId__c, SBQQ__BlockPrice__c, SBQQ__PricingMethod__c from SBQQ__QuoteLine__c where SBQQ__Quote__c = :quoteObj.id];	
                    if(!lstquoteLn.isEmpty()){	
                        for(SBQQ__QuoteLine__c q : lstquoteLn){	
                            if(q.SBQQ__PricingMethod__c!=CWS_ConstantClass.PRICINGMETHOD_BLOCK){	
                                pbeid.add(q.SBQQ__PricebookEntryId__c);	
                                mapPbToPrice.put(q.SBQQ__PricebookEntryId__c, q.SBQQ__ListPrice__c);	
                            }	
                            else if(q.SBQQ__BlockPrice__c!=null){	
                                mapBlockPrice.put(q.SBQQ__BlockPrice__c,q.SBQQ__ListPrice__c);	
                            }	
                        }	
                        List<PricebookEntry> lstPb = new List<PricebookEntry>([select id, UnitPrice from PricebookEntry where id IN :pbeid]);	
                        if(!mapBlockPrice.isEmpty()){	
                            blockPrice = [Select Id, SBQQ__Price__c from SBQQ__BlockPrice__c where id IN :mapBlockPrice.keySet()];	
                        }	
                        for(PricebookEntry pb : lstPb) {	
                            if(mapPbToPrice.containsKey(pb.id) && mapPbToPrice.get(pb.id)!= pb.UnitPrice.setScale(2,System.RoundingMode.HALF_UP)){	
                                setError = true;	
                            }	
                        }	
                        for(SBQQ__BlockPrice__c bp : blockPrice){	
                            if(mapBlockPrice.containsKey(bp.id) && mapBlockPrice.get(bp.id)!= bp.SBQQ__Price__c){	
                                setError = true;	
                            }	
                        }	
                    }	
                }	
            }	
            return setError;	
        }catch(Exception e){	
            CWS_ExceptionHandler.logException( e,'Quote' , 'refreshPriceOnQuote', '' , '', null, null , 'refreshPriceOnQuote' , null);	
            throw new AuraHandledException('Exception occurred during Refresh Price '+ e.getMessage());	
        }	
    }	
    @AuraEnabled	
    public static List<String> NBQuoteDefaults(){	
        List<String> valueMap = new List<String>();	
        try {	
            valueMap.add('{"fieldName":"RecordTypeId","fieldValue":"'+CWS_ConstantClass.QUOTE_RTYPE_NEW_EDIT+'"}');	
            return valueMap;	
        } catch (Exception e) {	
            CWS_ExceptionHandler.logException( e,'Quote' , 'NBQuoteDefaults', '' , '', null, null , 'NBQuoteDefaults' , null);	
            throw new AuraHandledException('Exception occurred during NBQuoteDefaults '+ e.getMessage());	
        }	
    }	
    //BED-208 Query ConnectWise Standard Pricebook	
    public static Pricebook2 queryCWPriceBook(){	
        String priceBook = CWS_ConstantClass.CONNECTWISE_PRICEBOOK;	
        return ([select id,name from Pricebook2 where name = :priceBook]);	
    }	
    // BED-8869	
    @future	
    public static void quoteCalcHelper(Id quoteID){	
        try {	
            CWS_QuoteReader qReader = new CWS_QuoteReader();	
            CWS_QuoteModel qModel = qReader.read(quoteID);	
            CWS_QuoteCalculator qCalcr = new CWS_QuoteCalculator();	
            qCalcr.calculate(qModel,CWS_ConstantClass.QUOTECALLBACK);	
        } catch (Exception e) {	
            CWS_ExceptionHandler.logException( e,'SBQQ__Quote__c' , 'CWS_CommonUtility', 'quoteCalculate' , '', null, null , 'quoteCalculate' , null);	
        }	
    }	
    Public static List<String> validateMinCommit(SBQQ__Quote__c quoteObj){	
        List<String> quoteErrorMessageList=new List<String>();	
        if(quoteObj!=null  && quoteObj.SBQQ__Opportunity2__c!=null){	
            Map<String, Integer> mapMonthValue=new Map<String, Integer>{ 'JAN'=>1, 'FEB'=>2, 'MAR'=>3, 'APR'=>4,	
                'MAY'=>5, 'JUN'=>6, 'JUL'=> 7, 'AUG'=> 8, 'SEP'=>9, 'OCT'=>10,	
                'NOV'=>11, 'DEC'=>12 };	
                    Set<String> lstMinCommitMonths=new Set<String>();	
            String monthString;	
            String yearString;	
            for(CWS_Minimum_Commit__c minCommit:[Select Id, Name, CWS_Legacy_ID__c,	
                                                 CWS_Monthly_Minimum_Commit__c, CWS_Month_Year__c from CWS_Minimum_Commit__c where	
                                                 CWS_Opportunity__c= :quoteObj.SBQQ__Opportunity2__c]){	
                                                     if(minCommit.CWS_Month_Year__c!=null){	
                                                         monthString=minCommit.CWS_Month_Year__c.subStringBefore('-').trim().toUpperCase();	
                                                         yearString=minCommit.CWS_Month_Year__c.subStringAfter('-').trim();	
                                                         lstMinCommitMonths.add(''+mapMonthValue.get(monthString)+'-'+yearString);	
                                                     }	
                                                 }	
            Set<String> expectedMinCommitMonths=new Set<String>();	
            Date startDate=quoteObj.SBQQ__StartDate__c;	
            Date endDate=quoteObj.SBQQ__EndDate__c;	
            Date tempDate=Date.newInstance(startDate.year(), startDate.month(), 1);	
            while(tempDate<=endDate){	
                expectedMinCommitMonths.add(''+tempDate.month()+'-'+String.valueOf(tempDate.year()).right(2));	
                tempDate=tempDate.addMonths(1);	
            }	
            if(!lstMinCommitMonths.containsAll(expectedMinCommitMonths)){	
                quoteErrorMessageList.add(System.Label.CWS_QuoteErrorMinCommitAcceptance);	
            }	
        }	
        return quoteErrorMessageList;	
    }	
    @future	
    public static void recalcQuote(Id quoteid){	
        try {	
            if (quoteid != null) {	
                SBQQ__Quote__c qt = new SBQQ__Quote__c(id=quoteid);	
                qt.CWS_Recalculation_DateTime__c = System.now();	
                update qt;	
            }	
        } catch (Exception e) {	
            CWS_ExceptionHandler.logException( e,'SBQQ__Quote__c' , 'CWS_CommonUtility', 'recalcQuote' , '', null, null , 'recalcQuote' , null);	
        }	
    }	
}