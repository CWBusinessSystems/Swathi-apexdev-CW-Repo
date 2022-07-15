/*
* Class Name  : CWS_ListPriceCalculationBatch
* Description : Batch class to calculate list price based on exchange rate and economic factors
* Created By  : Nirmal Kumar 
* Created On  : 4/2/2020

 * Modification Log:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer                Date                   Modification ID      Description 
 * ---------------------------------------------------------------------------------------------------------------------------------------
 * Nirmal Kumar             4/2/2020                BED-3492          Initial/First Version      
*/
Global class CWS_ListPriceCalculationBatch implements Database.Batchable<SObject>, Database.Stateful {
    
     Set<Id> pbentryList = new Set<Id>();
    global Integer updateValue=0;
    
    //Default Constructor
    Global CWS_ListPriceCalculationBatch(){  
            
    }

    //This constructor will be called to process list of pricebook entries for testing
     global CWS_ListPriceCalculationBatch(Set<Id> pbeList){
        pbentryList = pbeList;  
    }


    Global Database.QueryLocator start(Database.BatchableContext bc){
         String strQuery;
         strQuery = 'Select Id, Pricebook2.Name, Product2.Id, CWS_Price_Modified__c, Product2.CWS_Category__c, Product2.IsActive, Product2.CWS_EF_Attribute__c, CurrencyIsoCode, UnitPrice, CWS_CostPrice__c, CWS_Exception_Costprice__c, IsActive, CWS_Exception_Pricing__c from PricebookEntry where IsActive = True  and Product2.IsActive = True and CurrencyISOCode !=' + '\'USD\'' + 'and Pricebook2.Name = \'' + System.Label.CWS_ConnectwisePricebook + '\'';
        //Query to fetch pricebookentries which are active and which have exception price as False
         //Checks whether pricebook Ids is part of parameters for testing
        If(pbentryList.size()>0){
            strQuery = strQuery + ' and Id In:pbentryList';
        }  
         return Database.getQueryLocator(strQuery);
         

    }
    
    Global void execute(Database.BatchableContext bc, List<PriceBookEntry> scope){

        Map<String, Decimal> ecoFacMap = new Map<String, Decimal>();
        Map<Id, Decimal> pbeKeyMap = new Map<Id, Decimal>();
        Map<String, Decimal> exchangeRate = new Map<String, Decimal>();
        List<PricebookEntry> updPbe = new List<PricebookEntry>();
        Map<Id, Decimal> costKeyMap = new Map<Id, Decimal>();
        List<Product2> productList = new List<Product2>();
        Map<String, Decimal> bPKeyMap = new Map<String, Decimal>();
        Map<String, Decimal> bPZuoraKeyMap = new Map<String, Decimal>();
        //used to prepare keys of category and EW_Attribute
        String keyString;
        Set<Id> prodId = new Set<Id>();
        Integer qtyLimit = Integer.valueOf(System.Label.CWS_Custom_Metedata_Query_Limit);
        List<SBQQ__BlockPrice__c> blockPrice = new List<SBQQ__BlockPrice__c>();
        List<SBQQ__BlockPrice__c> updBP = new List<SBQQ__BlockPrice__c>();
        
        

        try{
            //Queries the economic factor table for all it's records
            CWS_PBE_Validation_Deactivation__c pbeValidation  = [Select Id, CWS_Deactivate__c from CWS_PBE_Validation_Deactivation__c limit 1];
            if(pbeValidation!=null){
            pbeValidation.CWS_Deactivate__c = true;
            Database.update(pbeValidation);
            }
            
            List<CWS_Economic_Factor__c> efList = new List<CWS_Economic_Factor__c>([Select ID, CWS_Category__c, CWS_Product_Type__c, CWS_Economic_Factor__c, CurrencyISOCode from CWS_Economic_Factor__c limit :qtyLimit]);
           //queries the exchange rate applied in the org
            List<CurrencyType> exchangeList = [Select ISOCode, ConversionRate, IsActive from CurrencyType where IsActive = True limit 50];

            for(PriceBookEntry pbe:scope){
                prodId.add(pbe.Product2.Id);
            }

            if(prodId.size()>0){
               productList = [Select Id, (Select Id, Unitprice, CWS_CostPrice__c from pricebookentries where CurrencyISOCode ='USD' and Pricebook2.Name =:System.Label.CWS_ConnectwisePricebook limit 1) from Product2 where isActive = True and Id =:prodId limit 4000];
                blockPrice = [Select Id, SBQQ__Price__c, CWS_Zuora_Price__c, CWS_Exception_Zuora_Price__c, CWS_Exception_Price__c, CurrencyIsoCode, SBQQ__Product__c,SBQQ__Product__r.CWS_Category__c,SBQQ__Product__r.CWS_EF_Attribute__c, SBQQ__Product__r.CWS_Source__c, SBQQ__LowerBound__c, SBQQ__UpperBound__c from SBQQ__BlockPrice__c where SBQQ__Product__c =:prodId limit 4000];
            }
            
            
               
         
           
            For(Product2 prod:productList){
                for(PriceBookEntry pbe:prod.Pricebookentries){
                        if(pbe.UnitPrice!=0){    
                      pbeKeyMap.put(prod.Id, pbe.UnitPrice);
                     }
                        if(pbe.CWS_CostPrice__c!=0 && pbe.CWS_CostPrice__c!=null){ 
                        costKeyMap.put(prod.Id, pbe.CWS_CostPrice__c);
                        }       
                }
            }

            for(SBQQ__BlockPrice__c bp:blockPrice){
                if(bp.SBQQ__Price__c!=0 && bp.CurrencyISOCode == 'USD'){    
                      bPKeyMap.put(bp.SBQQ__Product__c+';'+bp.SBQQ__LowerBound__c+'-'+bp.SBQQ__UpperBound__c, bp.SBQQ__Price__c);
                     }

                if(bp.CWS_Zuora_Price__c!=0 && bp.CWS_Zuora_Price__c!=null && bp.CurrencyISOCode == 'USD' && bp.SBQQ__Product__r.CWS_Source__c != CWS_ConstantClass.PRODUCT_SOURCE_CW){    
                      bPZuoraKeyMap.put(bp.SBQQ__Product__c+';'+bp.SBQQ__LowerBound__c+'-'+bp.SBQQ__UpperBound__c, bp.CWS_Zuora_Price__c);
                     }     
            }

            
            //Map of Exchange rate records
            for(CurrencyType exList : exchangeList){
            exchangeRate.put(exList.ISOCode, exList.ConversionRate);
            }

           //Map of economic factor records
            for(CWS_Economic_Factor__c ecoFac: efList){
               keyString = ecoFac.CWS_Category__c + ecoFac.CWS_Product_Type__c + ecoFac.CurrencyISOCode;
               ecoFacMap.put(keyString, ecoFac.CWS_Economic_Factor__c);
           }

           //Map of pricebookentries where the currency is USD and   Key is product Id and value is Unit Price
           
            //check whether exchangerate and pricebookentry map has been populated
            if(exchangeRate.size()>0 && (pbeKeyMap.size()>0 || costKeyMap.size()>0)){
                for(PricebookEntry pbe:scope){
                    keyString = pbe.Product2.CWS_Category__c + pbe.Product2.CWS_EF_Attribute__c;
                    Decimal unitPrice;
                    Decimal costPrice;
                    Boolean toUpdate = false;
                    if(!pbe.CWS_Exception_Pricing__c){
                    //updates pricebookentry record which has corresponding economic factor record
                    if(ecoFacMap.containsKey(keyString+pbe.CurrencyIsoCode) && exchangeRate.containsKey(pbe.CurrencyIsoCode) && pbeKeyMap.containsKey(pbe.Product2.Id)){
                        unitPrice = exchangeRate.get(pbe.CurrencyIsoCode)*pbeKeyMap.get(pbe.Product2.Id)*ecoFacMap.get(keyString+pbe.CurrencyIsoCode);
                        if(pbe.UnitPrice!=unitPrice){
                            pbe.UnitPrice = unitPrice;
                            pbe.CWS_Price_Modified__c = true;
                            toUpdate=true;
                        }      
                    }
                    //updates pricebookentry for records which doesn't have matching economic factor records
                    else if(!(ecoFacMap.containsKey(keyString+pbe.CurrencyIsoCode)) && exchangeRate.containsKey(pbe.CurrencyIsoCode) && pbeKeyMap.containsKey(pbe.Product2.Id)){
                        unitPrice =  exchangeRate.get(pbe.CurrencyIsoCode)*pbeKeyMap.get(pbe.Product2.Id);
                        if( pbe.UnitPrice!=unitPrice){
                            pbe.UnitPrice = unitPrice;
                            pbe.CWS_Price_Modified__c = true;
                            toUpdate=true;
                        }   
                    }
                }
                    if(!pbe.CWS_Exception_Costprice__c){
                    if(ecoFacMap.containsKey(keyString+pbe.CurrencyIsoCode) && exchangeRate.containsKey(pbe.CurrencyIsoCode)&& costKeyMap.containsKey(pbe.Product2.Id)){
                        costPrice = exchangeRate.get(pbe.CurrencyIsoCode)*costKeyMap.get(pbe.Product2.Id)*ecoFacMap.get(keyString+pbe.CurrencyIsoCode);
                        if(pbe.CWS_CostPrice__c!=costPrice){
                            pbe.CWS_CostPrice__c = costPrice;
                            pbe.CWS_Price_Modified__c = true;
                            toUpdate=true;
                        }
                    }
                    else if(!(ecoFacMap.containsKey(keyString+pbe.CurrencyIsoCode)) && exchangeRate.containsKey(pbe.CurrencyIsoCode)&& costKeyMap.containsKey(pbe.Product2.Id)){
                        costPrice = exchangeRate.get(pbe.CurrencyIsoCode)*costKeyMap.get(pbe.Product2.Id);
                         if(pbe.CWS_CostPrice__c!=costPrice){
                            pbe.CWS_CostPrice__c = costPrice;
                            pbe.CWS_Price_Modified__c = true;
                            toUpdate=true;
                        }
                    }
                }
                    if(toUpdate){
                        updPbe.add(pbe);
                    }
                }
            }

            if(exchangeRate.size()>0 && (bPKeyMap.size()>0 || bPZuoraKeyMap.size()>0)){
                for(SBQQ__BlockPrice__c bp:blockPrice){
                    keyString = bp.SBQQ__Product__r.CWS_Category__c + bp.SBQQ__Product__r.CWS_EF_Attribute__c;
                    Decimal Price;
                    Decimal zuoraPrice;
                    Boolean Updated = false;
                    if(bp.CurrencyISOCode!='USD' && !(bp.CWS_Exception_Price__c) && bpKeyMap.size()>0){
                    if(ecoFacMap.containsKey(keyString+ bp.CurrencyIsoCode) && exchangeRate.containsKey(bp.CurrencyIsoCode) && bpKeyMap.containsKey(bp.SBQQ__Product__c+';'+bp.SBQQ__LowerBound__c+'-'+bp.SBQQ__UpperBound__c)){
                        Price = exchangeRate.get(bp.CurrencyIsoCode)*bpKeyMap.get(bp.SBQQ__Product__c+';'+bp.SBQQ__LowerBound__c+'-'+bp.SBQQ__UpperBound__c)*ecoFacMap.get(keyString+bp.CurrencyIsoCode);
                        if(bp.SBQQ__Price__c!=Price){
                           bp.SBQQ__Price__c = Price;
                            Updated = true;
                        }      
                    }
                    //updates pricebookentry for records which doesn't have matching economic factor records
                    else if(!(ecoFacMap.containsKey(keyString+bp.CurrencyIsoCode)) && exchangeRate.containsKey(bp.CurrencyIsoCode) && bpKeyMap.containsKey(bp.SBQQ__Product__c+';'+bp.SBQQ__LowerBound__c+'-'+bp.SBQQ__UpperBound__c)){
                        Price =  exchangeRate.get(bp.CurrencyIsoCode)*bpKeyMap.get(bp.SBQQ__Product__c+';'+bp.SBQQ__LowerBound__c+'-'+bp.SBQQ__UpperBound__c);
                        if( bp.SBQQ__Price__c!=Price){
                            bp.SBQQ__Price__c = Price;
                            Updated = true;
                        }   
                    }
                }

                if(bp.CurrencyISOCode!='USD' && !(bp.CWS_Exception_Zuora_Price__c) && bpZuoraKeyMap.size()>0){
                    if(exchangeRate.containsKey(bp.CurrencyIsoCode) && bpZuoraKeyMap.containsKey(bp.SBQQ__Product__c+';'+bp.SBQQ__LowerBound__c+'-'+bp.SBQQ__UpperBound__c)){
                        zuoraPrice =  exchangeRate.get(bp.CurrencyIsoCode)*bpZuoraKeyMap.get(bp.SBQQ__Product__c+';'+bp.SBQQ__LowerBound__c+'-'+bp.SBQQ__UpperBound__c);
                        if(bp.CWS_Zuora_Price__c!=zuoraPrice){
                            bp.CWS_Zuora_Price__c = zuoraPrice;
                            Updated = true;
                         }   
                        }
                    }
                
            
                    if(Updated){
                        updBP.add(bp);
                    }
                }
            }
            
            

            //checks whether updPBE has records in it to update
            if(updPbe.size()>0){
               updateValue = updateValue + updPbe.size();
               List<Database.SaveResult> results =  Database.Update(UpdPbe, False);
               CWS_ExceptionHandler.logDMLSaveResults(results, 'CWS_ListPriceCalculationBatch' , 'BatchJob','Update Pricebookentries', null , null );
                }
            if(updBP.size()>0){
              updateValue = updateValue + updBP.size();
              List<Database.SaveResult> nresults =  Database.Update(updBP, False);  
              CWS_ExceptionHandler.logDMLSaveResults(nresults, 'CWS_ListPriceCalculationBatch' , 'BatchJob','Update BlockPriceEntries', null , null );
            }
            
        }

        catch(Exception e){
                 CWS_ExceptionHandler.logException( e,'BatchClass' , 'CWS_ListPriceCalculationBatch' , 'Execute' ,'', null , null ,'update' , null);
        }
        
        
    }
    
     Global void finish(Database.BatchableContext bc){
		try{
        List<Database.SaveResult> nresults = new List<Database.SaveResult>();
          AsyncApexJob job = new AsyncApexJob();    
            if(bc.getJobId()!=null){ 
             job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, LastProcessedOffset, TotalJobItems, ParentJobId FROM AsyncApexJob WHERE  Id = :bc.getJobId()];
         }
        //checks and retreives trigger batch job record which has been created during the click on trigger batch job button
           CWS_Trigger_Batch_Job__c triggerRecord = [SELECT ID, CWS_Status__c, createddate, CWS_No_of_Records_Processed__c from CWS_Trigger_Batch_Job__c where CWS_Status__c =:CWS_ConstantClass.TRIGGER_PROCESSING Order by createddate ASC limit 1];   
        //trigger batch job record gets updated with the status of the async job
           CWS_PBE_Validation_Deactivation__c pbValidation  = [Select Id, CWS_Deactivate__c from CWS_PBE_Validation_Deactivation__c limit 1];
           if(pbValidation!=null){
           pbValidation.CWS_Deactivate__c = false;
           Database.update(pbValidation);
           }
        if(triggerRecord!=Null){
        triggerRecord.CWS_Status__c = job.status;
        triggerRecord.CWS_No_of_Records_Processed__c = updateValue; 
         Database.SaveResult result = Database.update(triggerRecord,False);
         nresults.add(result);
         CWS_ExceptionHandler.logDMLSaveResults(nresults, 'CWS_ListPriceCalculationBatch' , 'BatchJob','update CWS_Trigger_Batch_Job__c', null , null );
        }
        CWS_ProductSyncPBEBatch pbe = new CWS_ProductSyncPBEBatch();
        Database.executeBatch(pbe);
    }
     catch(Exception e){
                 CWS_ExceptionHandler.logException( e,'BatchClass' , 'CWS_ListPriceCalculationBatch' , 'finish' ,'', null , null ,'update' , null);
        } 
       
    }
    

}