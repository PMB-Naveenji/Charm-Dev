/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ExportToExcelController.
* @Why   : Generated CWB tabs For Object field list CWB
* @When  : 18-NOV-2020.
* @Where : From ObjectFieldListReport VF page.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer               Date                   Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                   18-NOV-2020            CWB tabs generation         Created.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class ObjectFieldListReportController {
    
    public String xlsName {get;set;}
    public Map<Integer, Field> fieldsByOrder {get;set;}
    public Map<String, String> usageTextByFieldId {get;set;}
    public String xlsHeader {
        get {
            String strHeader = '';
            strHeader += '<?xml version="1.0" encoding="UTF-8"?>';
            strHeader += '<?mso-application progid="Excel.Sheet"?>';
            return strHeader;
        }
    }
    String baseURL = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v48.0/tooling/';
        
    public ObjectFieldListReportController(){
       xlsName = 'Object Field List';
       usageTextByFieldId = new Map<String, String>();
    }
    
    /*
    * @Method       : generateData.
    * @Description  : To generate data for CWB.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public void generateData () {
        getFieldDefinitions();
    }
    
    /*
    * @Method       : generateData.
    * @Description  : To generate FieldDefinition part for CWB.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public void getFieldDefinitions () {
        try {
            Integer i = 0;
            fieldsByOrder = new Map<Integer, Field>();
            Set <String> objectAPIs = getObjectAPIs();
            List <Schema.SObjectType> gd = Schema.getGlobalDescribe().Values();      
            Map<String, Schema.SObjectType> globalDescription = Schema.getGlobalDescribe();   
            List <Schema.SObjectField> fieldsDesc = new List <Schema.SObjectField>();
            List <FieldDefinition> fds = [SELECT Id, DurableId, EntityDefinition.QualifiedApiName, QualifiedApiName, MasterLabel, DataType, Label, LastModifiedDate, LastModifiedBy.Name 
                                        FROM FieldDefinition 
                                        WHERE EntityDefinition.QualifiedApiName in: objectAPIs];
            Map <String, Map<String, FieldDefinition>> fieldDefinitionByNameByObjectAPI = new Map <String, Map<String, FieldDefinition>>();
            Set <String> fieldDurableIDs = new Set <String>();
            for (FieldDefinition fieldDef: fds) {
                if (fieldDef.DurableId.contains('.')) {
                    fieldDurableIDs.add('\''+ fieldDef.DurableId.substring(fieldDef.DurableId.indexOf('.')+1, fieldDef.DurableId.length())+'\'');
                } else {
                    fieldDurableIDs.add('\''+fieldDef.DurableId+'\'');
                }
                if (fieldDefinitionByNameByObjectAPI.containsKey(fieldDef.EntityDefinition.QualifiedApiName)) {
                    fieldDefinitionByNameByObjectAPI.get(fieldDef.EntityDefinition.QualifiedApiName).put(fieldDef.QualifiedApiName, fieldDef);
                } else {
                    Map<String, FieldDefinition> fieldDefinitionByName = new Map<String, FieldDefinition>();
                    fieldDefinitionByName.put(fieldDef.QualifiedApiName, fieldDef);
                    fieldDefinitionByNameByObjectAPI.put(fieldDef.EntityDefinition.QualifiedApiName, fieldDefinitionByName);
                }
            }
            
            prepareUsage(fieldDurableIDs);
            for (String objectAPI: objectAPIs) {
                Schema.sObjectType objType = globalDescription.get(objectAPI);  
                Map<String, Schema.SObjectField > mapFieldList = objType.getDescribe().fields.getMap();    
                fieldsDesc = mapFieldList.values(); 
                for (Schema.SObjectField fieldDesc: fieldsDesc) {
                    Schema.DescribeFieldResult dfr = fieldDesc.getDescribe();
                    if (dfr.getLocalName() != 'Id'){ 
                        Field f = new Field();
                        f.objectAPI = objectAPI;
                        f.apiName = dfr.getLocalName();
                        f.fieldLabel = fieldDefinitionByNameByObjectAPI.get(objectAPI)?.get(f.apiName)?.MasterLabel;
                        f.dataType = pretifyDataType(fieldDefinitionByNameByObjectAPI.get(objectAPI)?.get(f.apiName)?.DataType, dfr);
                        f.helpText = dfr.getInlineHelpText()?.replace('<', '&lt;').replace('>', '&gt;');
                        f.formula = dfr.getCalculatedFormula()?.replace('<', '&lt;').replace('>', '&gt;');
                        
                        f.attributes = pretifyAttributes(dfr);
                        String durableId = fieldDefinitionByNameByObjectAPI.get(objectAPI)?.get(f.apiName)?.DurableId;
                        if (durableId != null && durableId.contains('.')) {
                            durableId  = durableId.substring(durableId.indexOf('.') + 1, durableId.length()); 
                        } 
                        f.usage = '';
                        
                        if (usageTextByFieldId.containsKey(durableId)) {
                            f.usage = usageTextByFieldId.get(durableId);
                        }
                        fieldsByOrder.put(i, f);
                        i++;
                    }
                }
            }
            System.debug(fieldsByOrder.size()  + ' '  + fieldsByOrder ) ;
        } catch(Exception e) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage());
            ApexPages.addMessage(myMsg);
            System.debug(e.getMessage() + ' ' + e.getStackTraceString() + ' ' + e.getLineNumber());
        }
    }
    
    public void prepareUsage(Set<String> fieldDurableIDs) {
        List<List<String>> dividedLists = new List<List<String>>();
        Integer partSize = 500;
        Integer i = 0;
        Integer j = 1;
        List<String> part = new List<String>();
        for (String fieldId: fieldDurableIDs) {
            part.add(fieldId);
            i++;
            if (i == partSize * j || i == fieldDurableIDs.size()) {
                dividedLists.add(part);
                part = new List<String>();
                j++;
            }
        }
        
        Map <String, Map<String, List<String>>> usageByFieldDurableId = new Map <String, Map<String, List<String>>>();
        System.debug(fieldDurableIDs.size());
        System.debug(dividedLists.size());
        System.debug(dividedLists.get(0).size() + ' ' + dividedLists.get(dividedLists.size() - 1).size());
        for (List <String> fieldDurableIDpart: dividedLists) {
            String fieldDurableIDStr = '';
            fieldDurableIDStr = String.join(fieldDurableIDpart, ',');
            HTTPRequest req = new HTTPRequest();
            req.setEndpoint(baseURL+'query?q=Select+MetadataComponentId,MetadataComponentName,MetadataComponentNamespace,'+
                                    'MetadataComponentType,RefMetadataComponentId,RefMetadataComponentName,RefMetadataComponentNamespace,RefMetadataComponentType+'+
                                    'FROM+MetadataComponentDependency+'+
                                    'WHERE+RefMetadataComponentType=\'CustomField\'+AND+RefMetadataComponentId+in+('+fieldDurableIDStr+')');
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
            req.setHeader('Content-Type', 'application/json');
            Http h = new Http();
            HttpResponse res = h.send(req);
           
            Result metadataDependenciesRes = (Result)JSON.deserialize(res.getBody(), Result.class);
            
            for (MetadataDependency md: metadataDependenciesRes.records) {
            
                md.RefMetadataComponentId = md.RefMetadataComponentId.substring(0, 15);
                System.debug(md);
                if (usageByFieldDurableId.containsKey(md.RefMetadataComponentId)) {
                    if (usageByFieldDurableId.get(md.RefMetadataComponentId).containsKey(md.MetadataComponentType)) {
                        usageByFieldDurableId.get(md.RefMetadataComponentId).get(md.MetadataComponentType).add(md.MetadataComponentName);
                    } else {
                        usageByFieldDurableId.get(md.RefMetadataComponentId).put(md.MetadataComponentType, new List<String>{md.MetadataComponentName});
                    }
                } else {
                    Map <String, List<String>> nameByType = new Map <String, List<String>>();
                    nameByType.put(md.MetadataComponentType, new List<String>{md.MetadataComponentName});
                    usageByFieldDurableId.put(md.RefMetadataComponentId, nameByType);
                }
            }
        }
        for (String fieldId: usageByFieldDurableId.keySet()) {
            String usageText = '{';
            for (String typ: usageByFieldDurableId.get(fieldId).keySet()) {
                usageText += typ + ': ';
                for (String name: usageByFieldDurableId.get(fieldId).get(typ)) {
                    usageText += name + '; '; 
                }
            }
            usageText += '}';
            usageTextByFieldId.put(fieldId, usageText);
        }
    }
    public String pretifyDataType (String dataType, Schema.DescribeFieldResult dfr) {
        if (dataType != null && dataType.startsWith('Text(') && dataType.lastIndexOf('(') > 4) {
            dataType = dataType.substring(0, dataType.lastIndexOf('('));
        }
        if (dataType == 'Picklist') {
            String picklistValues = '';
            for (Schema.PicklistEntry picklist: dfr.getPicklistValues()) {
                picklistValues += picklist.getLabel() + '; ';
            }
            dataType += '(' + picklistValues + ')';
        }
        if (String.valueOf(dfr.getType()) == 'MULTIPICKLIST') {
            dataType = 'MultiselectPicklist';
        }
        return dataType;
    }
    public String pretifyAttributes (Schema.DescribeFieldResult dfr) {
        String attributes = '';
        if (dfr.isUnique()) {
            attributes += 'Unique, ';
        }
        if (dfr.isCreateable() && !dfr.isNillable() && !dfr.isDefaultedOnCreate()) {
            attributes += 'Required, ';
        }
        if (dfr.isExternalID()) {
            attributes += 'ExternalId, ';
        }
        if (dfr.isCaseSensitive()) {
            attributes += 'Case Sensitive, ';
        }
        if (attributes.endsWith(', ')) {
            attributes = attributes.substring(0,attributes.length()-2);
        }
        return attributes;
    }
    public class Field{
        
        public String objectAPI {get;set;}
        public String fieldLabel {get;set;}
        public String apiName   {get;set;}
        public String dataType  {get;set;}
        public String helpText {get;set;}
        public String formula  {get;set;}
        public String attributes {get;set;}
        public String usage {get;set;}
        
        public Field() {

        }
       
    }
    public class Result {
        List <MetadataDependency> records;
    }
    public class MetadataDependency {
        public String MetadataComponentName;
        public String MetadataComponentType;
        public String RefMetadataComponentId;    
    }
    
    public Set <String> getObjectAPIs() {
        return new Set<String>{
            'Account', 'Action_Task__c', 'Activity__c', 'ADD_App_Settings__c', 'Additional_Approval__c',
            'Approver__c', 'Attachment__c', 'CMPL123__AcknowledgementMapping__c',
            'CMPL123__Action__c', 'CMPL123__Address__c', 'CMPL123__Audit_Activity_Type__c', 'CMPL123__Audit_Assessment__c',
            'CMPL123__Audit_Assessment_Template__c', 'CMPL123__Audit_History__c', 'CMPL123__Audit_History_Field_Change__c',
            'CMPL123__Audit_Trail_Entry__c', 'CMPL123__Audit_Trail_Translation_List__c', 'CMPL123__AuditTrail_Config__c',
            'CMPL123__CMPL_App_Config__c', 'CMPL123__Contact__c', 'CMPL123__Device__c', 'CMPL123__Job_Field_Map__c',
            'CMPL123__MDC_Acknowledgement_Entry__c', 'CMPL123__MDC_Field_Mapping__c', 'CMPL123__MDC_Ticket__c', 'CMPL123__MDC_Trigger__c'
            
            /*'CMPL123__MDCUserMapping__c', 'CMPL123__Memo__c', 'CMPL123__Product__c', 'CMPL123__RAR_Child_Test_Object__c',
            'CMPL123__RAR_Child2_Test_Object__c', 'CMPL123__RAR_Sub_Child_Test_Object__c', 'CMPL123__RAR_Target_User_Test_object__c',
            'CMPL123__Record_Access_Rule__c', 'CMPL123__SAML_Request__c', 'CMPL123__TWDLog__c', 'CMPL123__Valid_Child_Status__c',
            'CMPL123__WF_Action__c', 'CMPL123__WF_History__c', 'CMPL123__WF_Rule__c', 'CMPL123__WF_Status__c', 'CMPL123__WF_Step__c',
            'CMPL123__X123_Report_Section__c', 'CMPL123__X123_Report_Template__c', 'CMPL123__X123Job__c', 'CMPL123__X123Task__c',
            'CMPL123CME__Clinical_Investigation__c', 'CMPL123CME__Complaint__c', 'CMPL123CME__Complaint_Code__c', 'CMPL123CME__Complaint_Investigation__c'*/
            
            /*'CMPL123CME__Concomitant_Product__c', 'CMPL123CME__CVR__c',
            'CMPL123CME__EMDR__c', 
            'CMPL123CME__EMDR_Layout_Config__c'
            */
            
            /*'CMPL123CME__EMDRFDAConfig__c', 'CMPL123CME__EU_MIR__c', 'CMPL123CME__EU_MIR_Code__c', 'CMPL123CME__EU_MIR_Code_Choices__c',
            'CMPL123CME__HHE__c', 'CMPL123CME__Investigation__c', 'CMPL123CME__Investigation_Items__c', 'CMPL123CME__Investigation_Template__c',
            'CMPL123CME__Investigation_Template_Item__c', 'CMPL123CME__MDR__c', 'CMPL123CME__MDR_Code__c', 'CMPL123CME__MEDDEV__c',
            'CMPL123CME__Questionnaire__c', 'CMPL123CME__Questionnaire_Items__c', 'CMPL123CME__Questions_Template__c',
            'CMPL123CME__Questions_Template_Item__c', 'CMPL123CME__Registered_Site__c', 'CMPL123CME__Repair__c', 'CMPL123CME__Report_Mapping__c',
            'CMPL123CME__Submission_History__c', 'CMPL123CME__TGA__c', 'CMPL123CME__Vigilance__c', 'Contact__c', 'Country__c',
            'Country_Backup_Vigilance_Contact__c', 'Country_Group_Contact__c', 'Country_Submission_Type__c', 'Customer_Response__c'*/
            
            /*'Customer_Response_Master__c', 'EMDR_Integration__c', 'Error_Log__c', 'Event', 'Hazard_Assessment__c', 'Health_Hazard_Assessment__c',
            'Internal_System_Links__c', 'KI_Log__c', 'Meaningful_Data__c', 'Meaningful_Data_Request__c', 'Medical_Evaluation_Task__c',
            'Patient_Information__c', 'Post_Market_Risk_Assessment_Risk_Contr__c', 'pRE_Information__c', 'pRE_Question__c', 'Product_Lot__c',
            'Product_Ticket__c', 'Product2', 'RCML_Task_Product__c', 'Re_Open_Justification__c', 'Regulatory_Assessment__c',
            'Regulatory_Task__c', 'Related_Instrument__c', 'Reportability_History__c'*/
            
            /*'Return__c', 'Return_Form_Master__c', 'Risk_Assessment__c', 'RMF__c', 'Search__c', 'Search_Log__c',
            'T_T_Review_Task_Adverse_Trend__c', 'Task', 'Task__c', 'Task_Product_Evaluation_Investigation__c',
            'Ticket_Note__c', 'Ticket_Product_Evaluation_Investigation__c', 'Ticket_Review__c', 'Ticket_Search_Result__c',
            'Ticket_Serach__c', 'Ticket_Version__c', 'TPM__c', 'Tracking_Trending_Review_Task__c'*/
            
            /*'Translation_Item__c', 'Translation_Log__c', 'Translation_Task__c', 'Translation_Vendor__c', 'Trend_Item__c',
            'Trend_Item_Issue_Code__c', 'Trend_Item_Maintenance_Issue_Code__c', 'Trend_Item_Maintenance_Product__c', 'Trend_Item_Maintenance_Request__c',
            'Trend_Item_Maintenance_Trend_Bucket__c', 'Trend_Item_Product__c', 'Trend_Item_Trend_Bucket__c', 'TSB__c', 'User', 'ValidatedReportsConfig__c'*/
            };
    }
}