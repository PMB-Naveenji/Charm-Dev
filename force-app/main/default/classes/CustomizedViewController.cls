/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : CustomizedViewController.
* @Why   : To display the customized related list.
* @When  : 23-MAR-2017.
* @Where : From Action_Task_AuditTrigger Trigger.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID               Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    23-MAR-2017            Work ID / Case ID             Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    09-JUL-2020            Code Audit                    Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    07-SEP-2020            PMD Sanitizing                Added escaping of special sensitive symbols to url param.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    07-SEP-2020            Code Audit                    Added 'escapeSingleQuotes()' method call.
* --------------------------------------------------------------------------------------------------------------------------------------
* Anshika                  14-JUL-2022            CHaRM R2.2                    IPDR 190:Now Sorts Ticket Notes correctly.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class CustomizedViewController {
    public List<Sobject> complaintChildrenList { set; get; }
    public List<Schema.FieldSetMember> fieldSetValues { set; get; }

    /*
    * @Method       : CustomizedViewController
    * @Description  : Constructor.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : ApexPages.StandardController controller.
    * @Revision     : 14-JUL-2022 Anshika : Sort order was changed from DESC to ASC.
    */
    public CustomizedViewController(ApexPages.StandardController controller) {
        // PMD Sanitizing: added escapeJava() method
        String childRecordIdParam = ApexPages.currentPage().getParameters().get('id');
        String sObjNameParam = ApexPages.currentPage().getParameters().get('objName');
        String childRecordId = childRecordIdParam != null ? childRecordIdParam.escapeJava() : null;
        String sObjName =  sObjNameParam != null ? sObjNameParam.escapeJava() : null;
        complaintChildrenList = new List<Sobject>();

        if (childRecordId != null) {
            Id parentId;
            String relationshipName;
            String sortBy = 'CreatedDate DESC';

            if (sObjName == 'Meaningful_Data__c') {
                fieldSetValues = getFieldSets('Meaningful_Data_View','Meaningful_Data__c');
                relationshipName = 'Compliant__c';
            }
            if(sObjName == 'Ticket_Note__c'){
                fieldSetValues = getFieldSets('Ticket_Note_View','Ticket_Note__c');
                relationshipName = 'Ticket__c';
                sortBy = 'Ticket_Notes_Created_Date__c ASC';
            }
            if(sObjName =='Activity__c'){
                fieldSetValues = getFieldSets('Activity_View','Activity__c');
                relationshipName = 'Complaint__c';
            }
            if(sObjName =='Re_Open_Justification__c'){
                fieldSetValues = getFieldSets('Re_Open_Justification_View','Re_Open_Justification__c');
                relationshipName = 'Complaint__c ';
            }

            String queryString = 'SELECT ';

            for (Schema.FieldSetMember f :fieldSetValues) {
                queryString +=  f.getFieldPath() +',';
            }

            queryString = queryString.removeEnd(',');
            queryString = queryString + ' FROM ' + sObjName + ' WHERE ' + relationshipName + '= :childRecordId ';
            queryString = queryString + ' ORDER BY ' + sortBy;

            complaintChildrenList = Database.query(String.escapeSingleQuotes(queryString));
        }
    }

    /*
    * @Method       : getFieldSets.
    * @Description  : Static method used to get fieldset from object.
    * @Invoke       : From CustomizedViewController Constructor.
    * @Return       : List<Schema.FieldSetMember>.
    * @Params       : String fieldSetName, String ObjectName.
    */
    public static List<Schema.FieldSetMember> getFieldSets(String fieldSetName, String ObjectName){
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe();
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);

        return fieldSetObj.getFields();
    }
}