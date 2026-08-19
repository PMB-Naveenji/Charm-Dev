/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Capgemini
* @What  : ContentDocumentEUMIRTriggerHandler
* @Why   : Public class to manage all the custom coding invoked on the ContentDocument object..
* @When  : 11-AUG-2021
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID                         Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Varsha Hariharan        11-Aug-2021            CHaRM Release 2                           Created. 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Rohit Choudhary         1-Apr-2026            CHaRM Release 8                           Updated the "createCustomAttachment" method to add a record‑type 
																							check for EU MIR records and adjust the filename prefix to 'GB' 
																							when the record belongs to the GB MIR type.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
public class ContentDocumentEUMIRTriggerHandler extends TriggerHandler{
    //CHaRM R8: Retrieves the GB MIR (GB_MIR_7_2_1) Record Type Id used to detect GB records and apply the 'GB' filename prefix.
    public static Id recordType_GB_MIR_7_2_1 = Schema.SObjectType.CMPL123CME__EU_MIR__c .getRecordTypeInfosByDeveloperName() .get('GB_MIR_7_2_1') .getRecordTypeId();
    public override void beforeInsert() {
        createCustomAttachment((List<ContentDocumentLink>) Trigger.new);
    } 
    private static void createCustomAttachment(List<ContentDocumentLink> contFiles) {
        List<Attachment__c> listattachmentToUpdate = new List<Attachment__c>();
        Map<String, String> titleMap = new Map<String, String>();
        Map<String, ContentDocumentLink> mapAttachments = new Map<String, ContentDocumentLink>();
        List<Id> euMirIdList = new List<Id>();
        if(contFiles != NULL){
            List<Id> contIdList = new List<Id>();
            for(ContentDocumentLink iterateVar : contFiles){
                contIdList.add(iterateVar.ContentDocumentId);
            }
            List<ContentVersion> titleList = [select ContentDocumentId, FileExtension from ContentVersion WHERE ContentDocumentId IN : contIdList];
            for(ContentVersion loopVar : titleList){
                titleMap.put(loopVar.ContentDocumentId+'', loopVar.FileExtension);    
            }
        for (ContentDocumentLink filesObj : contFiles) {
            Id linkedId = filesObj.LinkedEntityId;
            Schema.DescribeSObjectResult objResult = linkedId.getSobjectType().getDescribe();
            String objName = objResult.getName();
            if (objName.equalsIgnoreCase('CMPL123CME__EU_MIR__c')) {
                filesObj.Visibility = 'AllUsers';
                euMirIdList.add(linkedId);
            }            
        }
        Map<Id,CMPL123CME__EU_MIR__c> euMirMap;
            if (euMirIdList.size() > 0 && Schema.SObjectType.CMPL123CME__EU_MIR__c.fields.CMPL123CME__Complaint__c.isAccessible()) {
                euMirMap = new Map<Id,CMPL123CME__EU_MIR__c>([SELECT Id, Name, CMPL123CME__Complaint__c, CMPL123CME__Type_Of_Report__c,RecordTypeId FROM CMPL123CME__EU_MIR__c
                                                                                            WHERE Id IN : euMirIdList]);

            }
        for (ContentDocumentLink objattach : contFiles) {
                if(euMirIdList.contains(objattach.LinkedEntityId)){
                    Attachment__c objattachment = new Attachment__c ();
                    String fileName;             
                    //CHaRM R8: Added EUMIR record type check logic to update the filename prefix to 'GB' for GB MIR record types.
                    if(euMirMap.get(objattach.LinkedEntityId).RecordTypeId == recordType_GB_MIR_7_2_1){
                        fileName = 'GB'+ euMirMap.get(objattach.LinkedEntityId).Name.substring(2) + '-' + euMirMap.get(objattach.LinkedEntityId).CMPL123CME__Type_Of_Report__c + '.' + titleMap.get(objattach.ContentDocumentId);
                    }else{
                        fileName = euMirMap.get(objattach.LinkedEntityId).Name + '-' + euMirMap.get(objattach.LinkedEntityId).CMPL123CME__Type_Of_Report__c + '.' + titleMap.get(objattach.ContentDocumentId);
                    }
                    objattachment.Name = fileName.length() > 80 ? fileName.substring(0,80) : fileName;
                    objattachment.Attachment_Title__c = fileName;
                    objattachment.Attachment_Type__c = 'Submission';
                    if(euMirIdList.contains(objattach.LinkedEntityId)){
                        if(!euMirMap.isEmpty() && euMirMap.containsKey(objattach.LinkedEntityId)){
                            objattachment.Ticket__c = euMirMap.get(objattach.LinkedEntityId).CMPL123CME__Complaint__c;
                        }
                        objattachment.EU_MIR__c = objattach.LinkedEntityId ;
                        mapAttachments.put(objattach.LinkedEntityId+fileName, objattach);
                    }
                    listattachmentToUpdate.add(objattachment);
                }
            }
            if(listattachmentToUpdate.size() > 0){
            try{
                insert listattachmentToUpdate;
                for(Attachment__c objAttachment : listattachmentToUpdate){
                    if(!mapAttachments.isEmpty() && mapAttachments.containsKey(objAttachment.EU_MIR__c+objAttachment.Name)){
                        mapAttachments.get(objAttachment.EU_MIR__c+objAttachment.Name).LinkedEntityId = objAttachment.Id;
                    }
                }
            }catch(Exception E){
                System.debug('=====E======='+E);
                if(E.getMessage().contains('Insufficient access')){
                    for(Attachment__c objAttachment : listattachmentToUpdate){
                        if(!mapAttachments.isEmpty() && mapAttachments.containsKey(objAttachment.EU_MIR__c+objAttachment.Name)){
                            mapAttachments.get(objAttachment.EU_MIR__c+objAttachment.Name).addError(System.Label.Custom_Attachment_Error_Message_based_on_Status);
                            return;
                        }
                    }
                }
            }

        }
    } 
    }
}