/*Class Name: CWS_ProductCategoryDetailsCntrl
*Description: Controller Class for the CWS_ProductCategoryDetailsComp VF component
*Created On: 4/28/2020
*Modification Log
*------------------------------------------------------------------------------------------
*Developer              Date            User Story              Description
*------------------------------------------------------------------------------------------
*Apurva Makuluri      05/07/2020        BED-6407               Email Notification to Sold to Contact.
*Aakash               29/07/2020        BED-8949               Email Notification for the Awaiting Quotes.
*/
public  class CWS_ProductCategoryDetailsCntrl
{
    public Id Oppid{get;set;}
    public Id AccId{get;set;}
    public string getopptylines()
    {
        List<OpportunityLineItem> opptyline;
        Set<String> setopptyline;
        Map<String,Id> prodcatmap =new Map<String,Id>();
        String[] temp1 = new String[]{};
        string productcatstring;
        opptyline = [SELECT id, Product2.CWS_Category__c  FROM OpportunityLineItem WHERE OpportunityId=: Oppid]; 
        if(opptyline.size()>0){   
            for(OpportunityLineItem os: opptyline){
                prodcatmap.put(os.Product2.CWS_Category__c, os.Id);
            }
        }
        if(prodcatmap.size()>0){   
            for(String pc: prodcatmap.keyset()){
                temp1.add(pc);
            }
        }           
        productcatstring = string.join(temp1,', ');
        return productcatstring;
    }

    /*
    * Method name  : getQuotesList
    * Description  : Method used for getting the Awaiting Status Quotes based on Account
    * Parameter    : None
    * Return Type  : List of Quotes
    * Developer    : Aakash
    */

    public List<SBQQ__Quote__c> lstQuotes{
        get{
            try{
                if(AccId!=null){
                    lstQuotes=[SELECT id,SBQQ__Account__r.Name,name,SBQQ__Status__c,SBQQ__Opportunity2__r.name,SBQQ__Opportunity2__r.StageName from SBQQ__Quote__c where SBQQ__Account__c =: AccId AND (SBQQ__Opportunity2__r.StageName <>: CWS_ConstantClass.OpportunityClosedLose_Stage OR SBQQ__Opportunity2__r.StageName <>: CWS_ConstantClass.OpportunityClosedWon_Stage) AND SBQQ__Status__c =: CWS_ConstantClass.QUOTE_STATUS_AWAIT_SIG];
                }
                return lstQuotes;   
            }
            catch(Exception e){
                CWS_ExceptionHandler.logException( e,'Quote' , 'ProdcutCategoryDetailsCntrl', 'lstQuotes' , '', null, null , 'lstQuotes' , null);
                return null;
            }
        }set;
    }
}