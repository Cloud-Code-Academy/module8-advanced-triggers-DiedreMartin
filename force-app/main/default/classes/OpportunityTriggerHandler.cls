public with sharing class OpportunityTriggerHandler extends TriggerHandler {
    private List<Opportunity> newOpps;
    private Map<Id, Opportunity> newOppsMap;
    private List<Opportunity> oldOpps;
    private Map<Id, Opportunity> oldOppsMap;


public OpportunityTriggerHandler(){
    this.newOpps = (List<Opportunity>) Trigger.new;
    this.newOppsMap = (Map<Id, Opportunity>) Trigger.newMap;
    this.oldOpps = (List<Opportunity>) Trigger.old;
    this.oldOppsMap = (Map<Id, Opportunity>) Trigger.oldMap;
    }
    
public override void beforeInsert(){
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
            for(Opportunity opp : this.newOpps){
                if (opp.Type == null){
                oppsToUpdate.add(opp);
            }    
        }
        OpportunityHelper.setType(oppsToUpdate);
    } 

public override void beforeDelete(){       // Prevent deletion of closed Opportunities
    List<Opportunity> closedOppsToValidate = new List<Opportunity>();
        for (Opportunity oldOpp : this.oldOpps){
            if (oldOpp.IsClosed){
                closedOppsToValidate.add(oldOpp);
                }
            }
            if (!closedOppsToValidate.isEmpty()){
        OpportunityHelper.validateCloseOpportunity(closedOppsToValidate); 
                
        }
    }

    public override void afterInsert(){ 
    // Create a new Task for newly inserted Opportunities
    List<Opportunity> insertedOpps = this.newOpps;
        OpportunityHelper.insertTask(insertedOpps);
    }
public override void beforeUpdate(){        
    Map<Id,Opportunity> oldMap = this.oldOppsMap; 
    List<Opportunity> updatedStageOpps = new List<Opportunity>();
        for (Opportunity oldOpp : oldMap.values()){
            Opportunity newOpp = this.newOppsMap.get(oldOpp.Id);
            if (oldOpp.StageName != newOpp.StageName) { 
            updatedStageOpps.add(newOpp);
            }
        }    
            OpportunityHelper.updateDescriptionFromStage(updatedStageOpps);    
    
            for(Opportunity opp : this.newOpps){
                    if(opp.Amount < 5000){
                    opp.addError('Opportunity amount must be greater than 5000');
                    }
                }
        Map<Id, Opportunity> oppPrimContactMap = new Map<Id, Opportunity>(); 
            for (Opportunity opp : this.newOppsMap.values()){
                IF (opp.Primary_Contact__c == null){
                        oppPrimContactMap.put(opp.id, opp);
                }
            }
            OpportunityHelper.assignPrimaryContactCEO(oppPrimContactMap);  
        }

    public override void afterDelete(){     
        List<Opportunity> deletedOpps = this.oldOpps;
            OpportunityHelper.notifyOwnersOpportunityDeleted(deletedOpps);
        } 

    public override void afterUndelete(){
        Map<Id, Opportunity> undeletedOppsMap = this.newOppsMap;
            OpportunityHelper.assignPrimaryContact(undeletedOppsMap);
        }    
    }









        


