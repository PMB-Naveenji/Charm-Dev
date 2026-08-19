/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDSearchController.
* @Why   : Handles all the customization involved on Custom Search.
* @When  : 23-MAR-2018.
* @Where : From ADDDefineSearchController class, ADDUtil class, ADDSearch page.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer               Date                   Modification ID           Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin  				  23-MAR-2018			 Work ID / Case ID         Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                   04-JUN-2020            Code Audit                Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                   15-JUN-2020            Code Audit                Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                   13-AUG-2020            Code Audit                Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class ADDSearchController {


    public String objectDetail {private set; get;}
    public Map<String, String> operatorMap {private set; get;}
    public String objectDetailJSON{set;get;}
    public String fieldDetailJSON{set;get;}
    public String selectedFields{set;get;}
    public Boolean displayResults{set;get;}
    public List<CMPL123CME__Complaint__c> complaints {private set; get;}
    public Map<String, String> fields {private set; get;}

    //Added - W-000079 - 02/08/2018 - Added for restricting some fields setup in Restricted_Search_Field__mdt metadata - Start
    private static Set<String> lstObjectRestrictedSearchFields {
        get{
            if(lstObjectRestrictedSearchFields == null){
                lstObjectRestrictedSearchFields = New Set<String>();
                for(Restricted_Search_Field__mdt objRestrictedSearchField : [SELECT Object_API_Name__c, Field_API_Names_Comma_separated__c FROM Restricted_Search_Field__mdt]){
                    if(objRestrictedSearchField.Field_API_Names_Comma_separated__c != null){
                        for(String strKey : objRestrictedSearchField.Field_API_Names_Comma_separated__c.split(',')){
                            lstObjectRestrictedSearchFields.add(objRestrictedSearchField.Object_API_Name__c+'-'+strKey.trim());
                        }
                    }
                }
            }
            return lstObjectRestrictedSearchFields;
        }set;
    }
     //Added - W-000079 - 02/08/2018 - Added for restricting some fields setup in Restricted_Search_Field__mdt metadata - End

    /*
    * @Method       : Constructor.
    * @Description  : To initialize the class variables.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public ADDSearchController() {
        displayResults = false;
        objectDetail = JSON.serialize(ADDUtil.getObjectDetails());
        operatorMap = new Map<String, String> {
            'equals' => '=', 'not equal to' => '!=',
            'less than' => '<', 'greater than' => '>',
            'less or equal' => '<=', 'greater or equal' => '>=' ,
            'contains text' => 'LIKE', 'contains in' => 'IN'
        };
        fields = new Map<String, String>();
    }

    /*
    * @Method       : getFieldDetails.
    * @Description  : To get fields from the specified object.
    * @Invoke       : From ADDDefineSearchController class, ADDSearch page.
    * @Return       : N/A.
    * @Params       : String objectAPI.
    */
    @remoteAction
    public static String getFieldDetails(String objectAPI){

        List<ADDS5DynamicSearchController.searchingDataInnerController> fieldDetails =
            new List<ADDS5DynamicSearchController.searchingDataInnerController>();
        Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();

        Schema.DescribeSObjectResult r = schemaMap.get(objectAPI).getDescribe();
        Map<String,Schema.SObjectField> objMap = r.fields.getMap();
        for(String fieldName : objMap.keyset()){
            Schema.DescribeFieldResult fieldDesc = objMap.get(fieldName).getDescribe();
            if(ADDStaticResources.INCLUDEDATATYPES.contains(String.valueOf(fieldDesc.getType())) && fieldDesc.isFilterable()) {
                //Added - W-000079 - 02/08/2018 - Added below condition for restricting field visibility setup in Restricted_Search_Field__mdt metadata
                if(lstObjectRestrictedSearchFields.size() == 0 || !lstObjectRestrictedSearchFields.contains(objectAPI+'-'+String.valueOf(fieldDesc.getName()))){
                    String strAPIName = '';
                    if(String.valueOf(fieldDesc.getType()).equalsIgnoreCase('REFERENCE') && fieldDesc.isCustom()){
                        strAPIName = String.valueOf(fieldDesc.getName()).removeEndIgnoreCase('__c') + '__r.Name';
                    }else if(!String.valueOf(fieldDesc.getType()).equalsIgnoreCase('REFERENCE')){
                        strAPIName = String.valueOf(fieldDesc.getName());
                    }

                    if(strAPIName != ''){
                        ADDS5DynamicSearchController.searchingDataInnerController searchWrapper  = new ADDS5DynamicSearchController.searchingDataInnerController();

                        searchWrapper.fieldAPIName = strAPIName;
                        searchWrapper.fieldLabel = String.valueOf(fieldDesc.getLabel());
                        searchWrapper.operator = null;
                        searchWrapper.operatorSign = null;
                        searchWrapper.value = null;
                        searchWrapper.sequenceNumber = null;
                        searchWrapper.datatype = String.valueOf(fieldDesc.getType());

                        fieldDetails.add(searchWrapper);
                    }

                }
            }
        }
        return JSON.serialize(fieldDetails);
    }

    /*
    * @Method       : fetchResults.
    * @Description  : To fetch search result.
    * @Invoke       : From ADDSearch page.
    * @Return       : N/A.
    * @Params       : String objectAPI.
    */
    public void fetchResults() {
        displayResults = true;
        fields = new Map<String, String>();
        if(selectedFields != null && selectedFields.length() > 0) {
            Map<String,String> childObjectAPIAndTicketFieldMap =
                (Map<String,String>)System.JSON.deserialize(objectDetailJSON, Map<String,String>.class);

            selectedFields = selectedFields + 'Id;Id';
            for(String fieldName : selectedFields.split(',')) {
                if(fieldName.contains(';')){
                    fields.put(fieldName.split(';')[0], fieldName.split(';')[1]);
                }
            }
            List<String> fieldSet = new List<String>();
            fieldSet.addAll(fields.keyset());
            fields.remove('Id');

            complaints = new List<CMPL123CME__Complaint__c>();
            Map<String,Set<String>> queryDataMap = ADDS5DynamicSearchController.createSearchQuery(fieldDetailJSON,'TicketSearch', fieldSet);
            String query;
            Set<String> childQueriesSet = new Set<String>();
            Set<String> searchingChildObjectsSet = new Set<String>();
            Set<String> ticketIdSet = new Set<String>();
            for(String queryData : queryDataMap.get('query')){
                 query = queryData;
            }
            childQueriesSet = queryDataMap.get('childQueriesSet');
            searchingChildObjectsSet = queryDataMap.get('searchingChildObjectsSet');
            if(String.isNotBlank(query)){
                for(sObject complaintAndChildData : Database.query(query)){
                    CMPL123CME__Complaint__c  ticketRecord = (CMPL123CME__Complaint__c)complaintAndChildData;
                    Boolean processSearchData = false;
                    if(searchingChildObjectsSet.size() > 0){
                        for(String childObject : searchingChildObjectsSet){
                            if(ticketRecord.getSObjects(childObject) != null && ticketRecord.getSObjects(childObject).size() > 0){
                                processSearchData = true;
                            }else{
                                processSearchData = false;
                                break;
                            }
                        }
                        if(processSearchData){
                            complaints.add(ticketRecord);
                        }
                    }else{
                        complaints.add(ticketRecord);
                    }
                }
            }else if(String.isBlank(query)){
                for(String childObjQuery : childQueriesSet){
                    for(Sobject childObj : Database.query(childObjQuery)){
                        String sobjectType = String.valueOf(childObj.getSobjectType());
                        if(childObjectAPIAndTicketFieldMap.size() > 0 &&
                            childObjectAPIAndTicketFieldMap.containsKey(sobjectType)){
                            if(childObj.get(childObjectAPIAndTicketFieldMap.get(sobjectType)) != null){
                                ticketIdSet.add(String.valueOf(childObj.get(childObjectAPIAndTicketFieldMap.get(sobjectType))));
                            }
                        }
                    }
                }
                String ticketFields = '';
                for(String field : fieldSet){
                    ticketFields +=  field + ',';
                }
                ticketFields = ticketFields.removeEnd(',');
                String ticketQuery = 'SELECT '+ ticketFields + ' FROM CMPL123CME__Complaint__c WHERE ID IN : ticketIdSet LIMIT 2000';
                for(sObject ticket : Database.query(ticketQuery)){
                        complaints.add((CMPL123CME__Complaint__c)ticket);
                }
            }
        }else {
            complaints = new List<CMPL123CME__Complaint__c>();
        }

    }

    /*
    * @Description  : Wrapper class to get Object details.
    */
    public class ObjectDetail {

        public String objectAPI{get;set;}
        public String objectLabel{get;set;}
        public String relatedFieldAPI{get;set;}
        public String relationshipName{get;set;}

        public ObjectDetail(String objectAPI, String objectLabel, String relatedFieldAPI,
            String relationshipName) {

            this.objectAPI = objectAPI;
            this.objectLabel = objectLabel;
            this.relatedFieldAPI = relatedFieldAPI;
            this.relationshipName = relationshipName;
        }
    }
}