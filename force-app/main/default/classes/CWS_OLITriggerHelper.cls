/*Class Name: CWS_OLITriggerHelper
*Description: Helper Class for CWS_OpportunityLineItemTriggerHandler
*Created By: Aditya
*Created On: 5/19/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Aditya             05/19/2020          BED-8552/226         Default Pricing fields from Product	
*/
public class CWS_OLITriggerHelper {
	

/*
* Method name  : beforeInsertUpdateMethod
* Description  : BED 8552/226/91 Use this method to write the before insert and update logic
* Parameter    : Map of new and old OLI records.
* Return Type  : None
* Developer    : Aditya
*/   
	public static void beforeInsertUpdatetMethod(List<OpportunityLineItem> newItems, Map<id,OpportunityLineItem> oldItems){
		// PLEASE VERIFY : This logic is running only for Comission only olis please validate before adding any changes.
		List<Id> oppList = new List<Id>();
		List<Id> prodList = new List<Id>();
		Map<Id,Opportunity> mapOliOpp = new Map<Id,Opportunity>();
		Map<Id,Product2> mapOliProd = new Map<Id,Product2>();
		Map<String,PriceBookEntry> pbeCurrencycodeMap = new Map<String,PriceBookEntry>();
		Decimal listPriceTemp;
		Integer qtyLimit = Integer.valueOf(System.Label.CWS_Custom_Metedata_Query_Limit);
		Map<String, Decimal> ecoFacMap = new Map<String, Decimal>();
		list<id> oppIds = new list<Id>();
		map<Id,Opportunity> OppMap = new map<Id,Opportunity>();
		Boolean forecastFlag = false;
		
		try{

			for(OpportunityLineItem oli:newItems){
				//check if it is Insert or Update scenario
			if(oldItems!=null){
					OpportunityLineItem oldOli = oldItems.get(oli.id);
					if(oli.CWS_Commission_Only__c && (oli.UnitPrice != oldOli.UnitPrice || oli.Quantity!=oldOli.Quantity)){
						prodList.add(oli.Product2Id);
						//oppIds.add(oli.opportunityid);
					}
					if(oli.CWS_Min_Commit__c == false &&(oli.CWS_Transaction_Type__c != oldOli.CWS_Transaction_Type__c || oli.CWS_ACVLine__c !=  oldOli.CWS_ACVLine__c || oli.CWS_Projected_Renewal_Value__c != oldOli.CWS_Projected_Renewal_Value__c)){
						forecastFlag = true;
					}
				}
				else if(oldItems == null){
					if(oli.CWS_Commission_Only__c){
						prodList.add(oli.Product2Id);
						oppIds.add(oli.opportunityid);
					}
				}
			}
			
			if(prodList.size()>0){

				//Start : BED - 91 Getting Eco Factor Information, Creating a map.
				if(oldItems==Null){
					//Map of economic factor records
					for(CWS_Economic_Factor__c ecoFac: [Select ID, CWS_Category__c, CWS_Product_Type__c, CWS_Economic_Factor__c, 
														CurrencyISOCode from CWS_Economic_Factor__c 
														limit :qtyLimit]){
						ecoFacMap.put(ecoFac.CWS_Category__c + ecoFac.CWS_Product_Type__c + ecoFac.CurrencyISOCode, ecoFac.CWS_Economic_Factor__c);
					}
				}
				// End : BED -91

				 if(oppIds.size()>0){
                   OppMap = new Map<Id,Opportunity>([select id,currencyIsoCode from opportunity where Id IN : oppIds]);
                }

				//Query Product and PBE related to OLI
				mapOliProd = new Map<id,Product2>([Select Id,CWS_SKU_Type__c,CWS_License_Type__c,
													CWS_Category__c,CWS_EF_Attribute__c,
													(Select Id, Unitprice,CurrencyIsoCode from pricebookentries 
														where Pricebook2.Name =:System.Label.CWS_ConnectwisePricebook and IsActive = true) 
													from Product2 where isActive = True and  id in:prodList ]);
				for(Product2 prod:mapOliProd.values()){
					for(PriceBookEntry pbe:prod.Pricebookentries){
						pbeCurrencycodeMap.put(prod.Id+pbe.currencyIsoCode,pbe);
					}
				}
			}	
				for(OpportunityLineItem oli:newItems){
					if(prodList.size()>0){
						if(oli.currencyIsoCode !=Null && pbeCurrencycodeMap != Null && pbeCurrencycodeMap.get(oli.Product2Id+oli.currencyIsoCode)!=Null  && OppMap != null && OppMap.get(oli.Opportunityid) != null ){
							listPriceTemp=pbeCurrencycodeMap.get(oli.Product2Id+OppMap.get(oli.Opportunityid).currencyIsoCode).UnitPrice;
							//oli.discount = ((listPriceTemp - oli.UnitPrice) / listPriceTemp)*100;
							oli.CWS_Discretionary_Disc__c = ((listPriceTemp - oli.UnitPrice) / listPriceTemp)*100;
							if(listPriceTemp != null && listPriceTemp !=0 ){
								oli.CWS_Discretionary_Amount__c=(listPriceTemp - oli.UnitPrice)* oli.Quantity;
							}
							oli.CWS_ACVLine__c = oli.unitprice*oli.Quantity*12 ;
							if( oldItems == null){
								oli.PriceBookEntryId=pbeCurrencycodeMap.get(oli.Product2Id+OppMap.get(oli.Opportunityid).currencyIsoCode).Id;
							}
						}
					}
						//Default product data incase of Insert only
						if(oldItems ==null){
							if(prodList.size()>0){
								//BED-5123 Skutype is converted to formula which will capture skutype of product.
								/* if(mapOliProd.get(oli.Product2Id).CWS_SKU_Type__c!=null){
								oli.CWS_SKU_Type__c = mapOliProd.get(oli.Product2Id).CWS_SKU_Type__c;
								}*/
								if(mapOliProd.get(oli.Product2Id).CWS_License_Type__c!=null){
								oli.CWS_License_Type__c = mapOliProd.get(oli.Product2Id).CWS_License_Type__c;
								}
								// Start BED -91 Assigning Eco Factor Based on Category, type and Currency
								if(!ecoFacMap.isEmpty() && ecoFacMap.get(mapOliProd.get(oli.Product2Id).CWS_Category__c+mapOliProd.get(oli.Product2Id).CWS_EF_Attribute__c+oli.currencyIsoCode) != Null){
									oli.CWS_Economic_Factor__c=ecoFacMap.get(mapOliProd.get(oli.Product2Id).CWS_Category__c+mapOliProd.get(oli.Product2Id).CWS_EF_Attribute__c+oli.currencyIsoCode);
								}
							}
							
							//Populating non min commit forecast qr during creation
							if(oli.CWS_Min_Commit__c == false && ((oli.CWS_ACVLine__c != null || oli.CWS_Projected_Renewal_Value__c != null) || String.isBlank(oli.CWS_Quote_Type__c) ) ){//quote type is null for commimission only
								
								if((oli.CWS_Quote_Type__c == CWS_ConstantClass.Opportunity_Type_Renewal || oli.CWS_Quote_Type__c == CWS_ConstantClass.Opportunity_Type_RenewalWithChange) &&                            
									(oli.CWS_Transaction_Type__c != null && (oli.CWS_Transaction_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWAL || oli.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_REASON_NEW || oli.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_REASON_NEW3 ||
									oli.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_ADD_ON || oli.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_SWAPIN ||								
									oli.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_SWAPOUT || oli.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_UPGRADE))){

										decimal projectedRenVal = oli.CWS_Projected_Renewal_Value__c == null ? 0 : oli.CWS_Projected_Renewal_Value__c;
										system.debug('ren val 2--'+projectedRenVal);
										oli.CWS_Non_Min_Commit_Forecast_QR__c = oli.CWS_ACVLine__c - projectedRenVal ;
								}  
								else if((oli.CWS_Quote_Type__c == CWS_ConstantClass.Opportunity_Type_New || oli.CWS_Quote_Type__c == CWS_ConstantClass.Opportunity_Type_Amendment || String.isBlank(oli.CWS_Quote_Type__c)) &&                            
									(oli.CWS_Transaction_Type__c != null && (oli.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_REASON_NEW || oli.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_REASON_NEW3 ||
									oli.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_ADD_ON || oli.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_SWAPIN ||								
									oli.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_SWAPOUT || oli.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_UPGRADE))){
										system.debug('bfr insert--');
                                        oli.CWS_Non_Min_Commit_Forecast_QR__c = oli.CWS_ACVLine__c;	
								}
							}

						}	
						
						//updation   
                        if(oldItems != null && forecastFlag == true){
                            
                            OpportunityLineItem oldOli = oldItems.get(oli.id);
							if((oli.CWS_Quote_Type__c == CWS_ConstantClass.Opportunity_Type_Renewal || oli.CWS_Quote_Type__c == CWS_ConstantClass.Opportunity_Type_RenewalWithChange) &&                            
								(oli.CWS_Transaction_Type__c != null && (oli.CWS_Transaction_Type__c == CWS_ConstantClass.QUOTE_TYPE_RENEWAL || oli.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_REASON_NEW || oli.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_REASON_NEW3 ||
								oli.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_ADD_ON || oli.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_SWAPIN ||								
								oli.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_SWAPOUT || oli.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_UPGRADE))){
								decimal projectedRenVal = oli.CWS_Projected_Renewal_Value__c == null ? 0 : oli.CWS_Projected_Renewal_Value__c;
									oli.CWS_Non_Min_Commit_Forecast_QR__c = oli.CWS_ACVLine__c - projectedRenVal;
							}  
							
							else if((oli.CWS_Quote_Type__c == CWS_ConstantClass.Opportunity_Type_New || oli.CWS_Quote_Type__c == CWS_ConstantClass.Opportunity_Type_Amendment || String.isBlank(oli.CWS_Quote_Type__c) ) &&                            
									(oli.CWS_Transaction_Type__c != null && (oli.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_REASON_NEW || oli.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_REASON_NEW3 ||
									oli.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_ADD_ON || oli.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_SWAPIN ||								
									oli.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_SWAPOUT || oli.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_UPGRADE))){										
										oli.CWS_Non_Min_Commit_Forecast_QR__c = oli.CWS_ACVLine__c;	
							} 
                            	
                            else if(oli.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_DOWNGRADE || oli.CWS_Transaction_Type__c == CWS_ConstantClass.TRANSACTION_TYPE_CANCEL ){
                                oli.CWS_Non_Min_Commit_Forecast_QR__c = 0;
                            }
                        } 
											
				}		


		} catch(Exception e){
			CWS_ExceptionHandler.logException( e,'OpportunityLineItem' , 'CWS_OLITriggerHelper', 'beforeupdate' , '', null, null , 'afterupdate' , null);
		}
	}
	/*
    * Method name  : afterInsertUpdateMethod
    * Description  : Total Price syncing with NetTotal
    * Parameter    : Map of new and old OLI records.
    * Return Type  : None
    * 
    */   
    public static void afterInsertUpdateMethod(List<OpportunityLineItem> newItems, Map<id,OpportunityLineItem> oldItems){
        list<Id> olis  = new list<Id>();
        for(OpportunityLineItem oli : newItems){
            if(oli.CWS_NetTotal__c != Null && oli.CWS_NetTotal__c !=oli.TotalPrice){
                olis.add(oli.id);
            }
        }
        //Future Callout to update Total Price with CWS_NetTotal
        if(olis.size()>0){
            updateTotalPrice(olis);
        }
    }

    @future
    public static void updateTotalPrice(List<Id> olis){
        List<OpportunityLineItem> oliNewItems = new List<OpportunityLineItem>() ;
		try{
			for(OpportunityLineItem oli : [select id,totalprice,CWS_NetTotal__c from OpportunityLineItem where Id IN :olis]){
				if(oli.CWS_NetTotal__c != Null && oli.CWS_NetTotal__c !=oli.TotalPrice){
					OpportunityLineItem newins = new OpportunityLineItem();
					newins.TotalPrice = oli.CWS_NetTotal__c;
					newins.id=oli.id;
					oliNewItems.add(newins);
				}
			}
			if(oliNewItems.size()>0){
				CWS_OpportunityLineItemTriggerHandler.AFTER_UPDATE_EXECUTED = true;
				CWS_OpportunityLineItemTriggerHandler.BEFORE_UPDATE_EXECUTED = true;
				CWS_OpportunityTriggerHandler.BEFORE_UPDATE_EXECUTED = true;
				CWS_OpportunityTriggerHandler.AFTER_UPDATE_EXECUTED = true;
				database.update (oliNewItems);
			}
		} catch(Exception e){
			CWS_ExceptionHandler.logException( e,'OpportunityLineItem' , 'CWS_OLITriggerHelper', 'beforeupdate' , '', null, null , 'afterupdate' , null);
		}
    }
}