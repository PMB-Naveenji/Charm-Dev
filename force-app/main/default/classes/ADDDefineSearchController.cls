/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDDefineSearchController.
* @Why   : Handles all the customization involved on VF pages of Ticket Review object.
* @When  : 23-MAR-2017.
* @Where : From ADDDefineSearch page, ADDDefineSearchView page.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID        Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin 				   23-MAR-2017			  Work ID / Case ID      Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                    28-JUL-2020            Code Audit             Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class ADDDefineSearchController {

    public String objectDetail {private set; get;}
    static Set<String> includeDatatype = new Set<String>{'TEXT', 'PHONE', 'FAX', 'DATE', 'EMAIL', 'PICKLIST', 'BOOLEAN'};
    public Map<String, String> operatorMap {private set; get;}
    public String objectDetailJSON{set;get;}
    public String fieldDetailJSON{set;get;}
    public String selectedFields{set;get;}
    public Boolean displayResults{set;get;}
    public List<CMPL123CME__Complaint__c> complaints {private set; get;}
    public List<String> fields {private set; get;}

    public Search__c search {set; get;}

    /*
    * @Method       : Constructor.
    * @Description  : To initialize the value from the VF page.
    * @Invoke       : From ADDDefineSearch page, ADDDefineSearchView page.
    * @Return       : N/A.
    * @Params       : ApexPages.StandardController controller.
    */
    public ADDDefineSearchController(ApexPages.StandardController controller) {
        displayResults = false;
        String trId = ApexPages.currentPage().getParameters().get('tid');
        String rId = ApexPages.currentPage().getParameters().get('id');
        if(rId != null && rId.length() > 3){
            search = [SELECT Id, Name, Ticket_Review__c, Search_Criteria__c, Criteria__c, Search_Description__c FROM Search__c WHERE Id=:rId];
        }else {
            search = new Search__c(Ticket_Review__c = trId);
        }

        objectDetail = JSON.serialize(ADDUtil.getObjectDetails());
        operatorMap = new Map<String, String> {
            'equals' => '=', 'not equal to' => '!=',
            'less than' => '<', 'greater than' => '>',
            'less or equal' => '<=', 'greater or equal' => '>=' ,
            'contains text' => 'LIKE', 'contains in' => 'IN'
        };
    }

    /*
    * @Method       : save.
    * @Description  : To initialize the value from the VF page.
    * @Invoke       : From ADDDefineSearch page, ADDDefineSearchView page.
    * @Return       : N/A.
    * @Params       : ApexPages.StandardController controller.
    */
    public PageReference save() {
        //TODO get the URL dynamically
        upsert search;
        return returnToPage();
        /*
        PageReference pr = new PageReference('https://c.cs4.visual.force.com/'+search.Ticket_Review__c);
        pr.setRedirect(true);
        return pr;
        */
    }

    /*
    * @Method       : cancel.
    * @Description  : To return to page.
    * @Invoke       : From ADDDefineSearch page, ADDDefineSearchView page.
    * @Return       : N/A.
    * @Params       : ApexPages.StandardController controller.
    */
    public PageReference cancel(){
        return returnToPage();
        /*
        PageReference pr = new PageReference('https://c.cs4.visual.force.com/'+search.Ticket_Review__c);
        pr.setRedirect(true);
        return pr;
        */

    }

    /*
    * @Method       : returnToPage.
    * @Description  : To return to same page.
    * @Invoke       : From ADDDefineSearch page, ADDDefineSearchView page.
    * @Return       : N/A.
    * @Params       : ApexPages.StandardController controller.
    */
    public PageReference returnToPage(){
        String url = System.URL.getSalesforceBaseUrl().toExternalForm() + '/'+search.Ticket_Review__c;
        PageReference pr = new PageReference(url);
        pr.setRedirect(true);
        return pr;
    }

    /*
    * @Method       : getFieldDetails.
    * @Description  : To search and get field details.
    * @Invoke       : From ADDDefineSearch page, ADDDefineSearchView page.
    * @Return       : N/A.
    * @Params       : String objectAPI.
    */
    @remoteAction
    public static String getFieldDetails(String objectAPI){
        return ADDSearchController.getFieldDetails(objectAPI);
    }
}