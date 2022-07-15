/*Class Name: CWS_ContentDocumentLinkHelper
*Description: Helper for CWS_ContentDocumentLinkTrigger
*Created By: Esha
*Created On: 29/05/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Esha                  29/05/2020        BED-3096     Attach signed agreement document to respective account and quote
*Ankit                 25/06/2020        BED-7322     Share Disty documents with all users when agreement is of Disty RT
*/

public class CWS_ContentDocumentLinkHelper {
    public static void afterInsert(Map<Id, ContentDocumentLink> newItems){
        try{
            Set<ID> contentDocIds = new Set<ID>();  
            for(ContentDocumentLink cdl: newItems.values()){
                contentDocIds.add(cdl.ContentDocumentId);
            }
            List<ContentDocumentLink> cdlList;
            Set<Id> agrmntIds = new Set<Id>();         
            Map<Id,Id> aggMapforAccount = new Map<Id,Id>(); 
            Map<Id,Id> aggMapforQuote = new Map<Id,Id>();
            Map<String,String> parentRecMapAccount = new Map<String,String>(); 
            Map<String,String> parentRecMapQuote = new Map<String,String>(); 
            for(ContentDocumentLink cdlObj: newItems.values()){   
               if((cdlObj.LinkedEntityId).getSObjectType().getDescribe().getName() == 'Apttus__APTS_Agreement__c'){ 
                   //Check if file is uploaded to agreement object  
                   agrmntIds.add(cdlObj.LinkedEntityId);
                }                          
            }
            
            set<string> distyDocs = new set<string>();
            for(Apttus__APTS_Agreement__c agg:[select id,CWS_Quote__c,Apttus__Account__c,recordTypeID from Apttus__APTS_Agreement__c where Id IN:agrmntIds]){
                aggMapforAccount.put(agg.Id, agg.Apttus__Account__c);
                if(agg.CWS_Quote__c != null){
                    aggMapforQuote.put(agg.Id, agg.CWS_Quote__c);
                }
                //Start BED-7322 Getting the agreement Ids with Disty/Reseller RT 
                if(agg.recordTypeID == CWS_ConstantClass.Distributor_Agreement_RT){
                    distyDocs.add(agg.Id);
                } 
                //End BED-7322         
            }
            cdlList = [Select Id,ContentDocument.Title,LinkedEntityId from ContentDocumentLink where Id IN :newItems.keySet() AND LinkedEntityId IN : agrmntIds];
            
            List<Apttus__APTS_Agreement__c> agreementList = new List<Apttus__APTS_Agreement__c>();
            Decimal docs = 0;
            set<string> shareAllUsers = new set<string>();
            for(ContentDocumentLink cdl: cdlList){
                Apttus__APTS_Agreement__c agreementRec = new Apttus__APTS_Agreement__c();
                if((cdl.LinkedEntityId).getSObjectType().getDescribe().getName() == 'Apttus__APTS_Agreement__c' && cdl.ContentDocument.Title.toLowerCase().contains(CWS_ConstantClass.signed_Document_Name.toLowerCase())){ //Check if signed file is uploaded on agreement object   
                    if((aggMapforAccount.get(cdl.LinkedEntityId)).getSObjectType().getDescribe().getName() == 'Account'){ //Check if Agreement parent is Account 
                        parentRecMapAccount.put(cdl.ContentDocumentId, aggMapforAccount.get(cdl.LinkedEntityId)); //Map<ContentDocumentId,AccountId>
                        //Start BED-7322 Getting the Disty/Reseller Content Document IDS
                        if(distyDocs.contains(cdl.LinkedEntityId)){
                            shareAllUsers.add(cdl.ContentDocumentId);
                        }
                        //End BED-7322
                    }
                        //BED-3024 Update no. of signed docs field  
                        agreementRec.Id = cdl.LinkedEntityId;
                        agreementRec.CWS_No_of_Signed_Docs__c = docs + 1;
                        //BED-3069 Update Agreement Document Name field
                        agreementRec.CWS_Agreement_Document_Name__c = cdl.ContentDocument.Title;
                        agreementList.add(agreementRec);
                        
                        
                }                         
            }   
            if(agreementList.size() > 0){
                update agreementList;
            }
            List<ContentDocumentLink> cdl_List = new List<ContentDocumentLink>();            
            for(String str: parentRecMapAccount.keySet()){  
                ContentDocumentLink cdl = new ContentDocumentLink(); // Content Document Link to share the file with Account(Parent) record   
                {
                    cdl.LinkedEntityId = parentRecMapAccount.get(str); // Account ID           
                    cdl.ContentDocumentId = str; //Content Dcoument ID
                    //Start BED-7322 Assigning Disty Reseller Document Share to all users
                    if(shareAllUsers.contains(str)){
                        cdl.Visibility = CWS_ConstantClass.ContentDocLink_Visibility_ALLUSERS;
                    }else{                
                        cdl.Visibility = CWS_ConstantClass.ContentDocLink_Visibility;                  
                    }
                    //End BED-7322
                    cdl.ShareType = CWS_ConstantClass.ContentDocLink_ShareType;
                    cdl_List.add(cdl);  
                }
            }               
            if(cdl_List.size()>0) {             
                insert cdl_List;     
            }
            //Attaching document to Quote    
            for(ContentDocumentLink cdl: cdlList){
                if((cdl.LinkedEntityId).getSObjectType().getDescribe().getName() == 'Apttus__APTS_Agreement__c' && cdl.ContentDocument.Title.toLowerCase().contains(CWS_ConstantClass.signed_Document_Name.toLowerCase())){ //Check if signed file is uploaded on agreement object   
						if( !aggMapforQuote.isEmpty() && aggMapforQuote.containskey(cdl.LinkedEntityId) &&(aggMapforQuote.get(cdl.LinkedEntityId)).getSObjectType().getDescribe().getName() == 'SBQQ__Quote__c') //Check if Agreement parent is Quote 
                        if(aggMapforQuote.containsKey(cdl.LinkedEntityId)){
                            parentRecMapQuote.put(cdl.ContentDocumentId, aggMapforQuote.get(cdl.LinkedEntityId)); //Map<ContentDocumentId,QuoteId>
                        }
                }                         
            }         
            List<ContentDocumentLink> cdl_List_Quote = new List<ContentDocumentLink>();           
            for(String str: parentRecMapQuote.keySet()){  
                ContentDocumentLink cdl = new ContentDocumentLink(); // Content Document Link to share the file with Quote(Parent) record   
                {
                    cdl.LinkedEntityId = parentRecMapQuote.get(str); // Quote ID           
                    cdl.ContentDocumentId = str; //Content Document ID       
                    cdl.ShareType = CWS_ConstantClass.ContentDocLink_ShareType;                  
                    cdl.Visibility = CWS_ConstantClass.ContentDocLink_Visibility_ALLUSERS; 
                    cdl_List_Quote.add(cdl);  
                }
            }        
            if(cdl_List_Quote.size()>0){            
                insert cdl_List_quote;
            }
        }catch(Exception e){
            CWS_ExceptionHandler.logException( e,'Content Document Link' , 'CWS_ContentDocumentLinkHelper', 'afterInsertMethod' , '', null, null , 'Afterinsert' , null);
        }
    }
	/*public static void afterDelete(Map<Id,ContentDocumentLink> contentDocMap){
        try{
            Set<Id> agrmntIds = new Set<Id>();
            List<Apttus__APTS_Agreement__c> agreementList = new List<Apttus__APTS_Agreement__c>();
            List<ContentDocumentLink> cdlList = [Select Id,ContentDocument.Title,LinkedEntityId from ContentDocumentLink where Id IN :contentDocMap.keySet() AND LinkedEntityId IN : agrmntIds]; 
            
            for(ContentDocumentLink cdlObj: cdlList){  
                Apttus__APTS_Agreement__c agreementRec = new Apttus__APTS_Agreement__c();
                if((cdlObj.LinkedEntityId).getSObjectType().getDescribe().getName() == 'Apttus__APTS_Agreement__c' && cdlObj.ContentDocument.Title.toLowerCase().containsIgnoreCase(CWS_ConstantClass.signed_Document_Name.toLowerCase())){ 
                    agreementRec.Id = cdlObj.LinkedEntityId;
                    agreementRec.CWS_No_of_Signed_Docs__c = 0;
                    agreementList.add(agreementRec);
                }                          
            }
            if(agreementList.size() > 0){
                update agreementList;
            }
        }catch(Exception e){
            CWS_ExceptionHandler.logException( e,'Content Document Link' , 'CWS_ContentDocumentLinkHelper', 'afterDeleteMethod' , '', null, null , 'AfterDelete' , null);
        }    
    }*/
}