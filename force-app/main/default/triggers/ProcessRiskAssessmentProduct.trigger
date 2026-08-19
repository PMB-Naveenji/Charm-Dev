/* 
*  --------------------------------------------------------------------------------------------------------------------------------------
*  @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
*  @What  : ProcessRiskAssessmentProduct
*  @Why   : To handle all the customization involved on Risk_Assessment__c object.
*  @When  : 19-JUN-2019
*  @Where : From Risk_Assessment__c object Events
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID            Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   oivan                    15-MAY-2020            CHARM-2586                 Added condition to skip code for Data Loader User
*                                                   (Migrated process issue)
*  --------------------------------------------------------------------------------------------------------------------------------------
*   DSkak                    04-06-2020             Code Audit                 Removed 'System.debug()'.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    15-06-2020             Code Audit                 Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   DSkak                    02-07-2020             Code Audit                 Added header trigger description.
*  --------------------------------------------------------------------------------------------------------------------------------------
*/

trigger ProcessRiskAssessmentProduct on Risk_Assessment__c (before delete, after insert, after update, after delete) {
    
    //Condition added for CHARM-2586 to skip the code for Data Loader User
    if (!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
     
        if (Trigger.isBefore && Trigger.isDelete) {
            Set<ID> pmrdIDSet = new Set<ID>();
            for(Risk_Assessment__c rs : Trigger.Old){
                if(rs.Post_Market_Risk_Asst_Risk_Ctrl__c != null){
                    pmrdIDSet.add(rs.Post_Market_Risk_Asst_Risk_Ctrl__c);        
                }
            }
            
            Map<ID,Post_Market_Risk_Assessment_Risk_Contr__c > pmraIdAndRecMap = new Map<ID,Post_Market_Risk_Assessment_Risk_Contr__c >([SELECT ID, CMPL123_WF_Status__c FROM Post_Market_Risk_Assessment_Risk_Contr__c
                                                                                                                                        WHERE ID IN : pmrdIDSet]);
            
            if(pmraIdAndRecMap.size() > 0){
                for(Risk_Assessment__c rsOld : Trigger.Old){
                    if(pmraIdAndRecMap.containsKey(rsOld.Post_Market_Risk_Asst_Risk_Ctrl__c) 
                    && (pmraIdAndRecMap.get(rsOld.Post_Market_Risk_Asst_Risk_Ctrl__c).CMPL123_WF_Status__c == 'Closed-Done' 
                        || pmraIdAndRecMap.get(rsOld.Post_Market_Risk_Asst_Risk_Ctrl__c).CMPL123_WF_Status__c == 'Closed-Voided')){
                            rsOld.addError('Insufficient Access');
                        }
                    
                }
            }
        }
        if (Trigger.isAfter) {
            ReportsRelatedDataUtil.updatePMRAWithRiskAssessmentsData(Trigger.old, Trigger.new);
        }
    }
}