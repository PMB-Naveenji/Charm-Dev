/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019 Sparta Systems, Inc.
* @What  : TranslationTaskWithProdEvalMDCCustom.
* @Why   : W-000173, it is used to generate CSV file and attach it in attachment object.
* @When  : 12-SEP-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                  12-SEP-2018            Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  04-JUN-2020            Code Audit                      Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  09-JUL-2020            Code Audit                      Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

global class TranslationTaskCreateCSV {
    /*
    * @Method       : generateTranslationTaskCreateCSV.
    * @Description  : Webservice method checks whether Translation Task's workflow status is 'In Process'
    *                   and record type is 'Text Translation'.
    * @Invoke       : From TranslationTaskCreateCSV class.
    * @Return       : String.
    * @Params       : String strRecordId.
    */
    webservice Static String generateTranslationTaskCreateCSV(String strRecordId) {
        List<Translation_Item__c> lstTranslationItems = New List<Translation_Item__c>();
        if(strRecordId != null && strRecordId != ''){
            for(Translation_Item__c objTranslationItem
                : [SELECT Id, Name, Field_Name__c, Native__c, Translated__c, Translation_Task__c, Translation_Task__r.Urgency__c,Translation_Task__r.Task_Comments__c,Translation_Task__r.Vendor_Name__r.Name,
                   Translation_Task__r.Name, Translation_Task__r.Parent_Ticket__r.Registration_Ticket__c, Translation_Task__r.Vendor_Name__r.Vendor_Email__c,Translation_Task__r.Vendor_Name__c
                   FROM Translation_Item__c WHERE Translation_Task__c =: strRecordId AND Translation_Task__r.CMPL123_WF_Status__c = 'In Process'
                   AND Translation_Task__r.RecordType.Name = 'Text Translation' ORDER BY
                   Translation_Task__r.Parent_Ticket__r.Registration_Ticket__c]) {
                       if (objTranslationItem.Translated__c == null) {
                           lstTranslationItems.add(objTranslationItem);
                       }
                   }
        } else {
            lstTranslationItems = New List<Translation_Item__c>();
        }
        if(lstTranslationItems.size() > 0){
            return generateAttachment(lstTranslationItems, strRecordId);
        }else{
            return 'No Records Found';
        }
    }

    /*
    * @Method       : generateAttachment.
    * @Description  : Private method used to generate csv and attach in attachment object'.
    * @Invoke       : From TranslationTaskCreateCSV class.
    * @Return       : String.
    * @Params       : List<Translation_Item__c> lstTranslationItems, String strRecordId.
    */
    @testVisible
    private static String generateAttachment(List<Translation_Item__c> lstTranslationItems, String strRecordId){

        try{
            String delimeter = ',';
            String csvHeader = 'Field Name'+delimeter+'Ticket Number'+delimeter+'Native'+delimeter+'Translated'+delimeter+'Related Id'+delimeter+'Urgency\n';
            String csvBody = '';
            Set<String> relatedTaskIds = New Set<String>();

            for(Translation_Item__c objTranslationItem : lstTranslationItems){

                if(objTranslationItem.Translated__c == null){
                    csvBody += (objTranslationItem.Field_Name__c.contains(',') ? '\"'+ objTranslationItem.Field_Name__c + '\"' : objTranslationItem.Field_Name__c) + delimeter + objTranslationItem.Translation_Task__r.Parent_Ticket__r.Registration_Ticket__c + delimeter;
                    csvBody += objTranslationItem.Native__c.contains('\n') || objTranslationItem.Native__c.contains(',') ? '\"'+ objTranslationItem.Native__c + '\"' + delimeter : objTranslationItem.Native__c + delimeter;
                    csvBody += objTranslationItem.Translated__c != null ? objTranslationItem.Translated__c + delimeter + objTranslationItem.Id +delimeter+ objTranslationItem.Translation_Task__r.Urgency__c+ '\n' : ''+delimeter + objTranslationItem.Id +delimeter+ objTranslationItem.Translation_Task__r.Urgency__c+ '\n';
                    relatedTaskIds.add(objTranslationItem.Translation_Task__c);
                }

            }
            String fileBody = csvHeader + csvBody;
            long lngTime = System.now().getTime();

            Translation_Log__c objTranslationLog = new Translation_Log__c(Translation_Task_Id__c = JSON.serializePretty(relatedTaskIds));
            insert objTranslationLog;

            Attachment objAttachment = New Attachment();
            objAttachment.Body = Blob.valueOf(fileBody);
            objAttachment.Name = lngTime+'ManualAttachment('+objTranslationLog.Id+').csv';
            objAttachment.ParentId = strRecordId;
            objAttachment.ContentType = 'text/csv; charset=UTF-8';

            insert objAttachment;
            return 'Success';
        }catch(Exception exp){
            return exp.getMessage();
        }
    }
}