using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Attention as Att;

class AscentDataFieldView extends Ui.SimpleDataField {

	var lastAltitudes=new [MaxN];
	var lastPositions=new [MaxN];
	var lastTimes = new [MaxN];
	var Npoints;
	var MaxN=10;					//number of points in the buffer arrays
	var lastPos;
	var slopeThreshold = 0.03;
	
	var lastAscentStatus;
	var ascentElevationStart;
	var ascentTimerStart;
	
	var lastVal;
	
    //! Set the label of the data field here.
    function initialize() {
        label = "Last Hill";
        Npoints = 0;
        lastAltitudes=new [MaxN];
        lastPositions=new [MaxN];
        lastTimes = new [MaxN];
        
        lastPos=0;
        lastVal=0;
        
        lastAscentStatus = 0;
        ascentElevationStart = 0;
        ascentTimerStart = 0;
    }

    //! The given info object contains all the current workout
    //! information. Calculate a value and return it in this method. 
    function compute(info) {
        // See Activity.Info in the documentation for available information.

		var alt = info.altitude;
		var pos = info.elapsedDistance;
		var time = info.timerTime;

		if(alt!=null && (pos-lastPos)>0.1)
		{
			lastPos = pos;	
			if(Npoints<MaxN)
			{
			//filling the array during the activity startup
				lastAltitudes[Npoints]=alt;
				lastPositions[Npoints]=pos;
				lastTimes[Npoints] = time;
				Npoints = Npoints+1;
				lastVal=Npoints;
			}
			else
			{
				//and updates the arrays with the FIFO logic
				for(var i=0; i<MaxN-1; i++)						//up to MaxN-1 !
				{
					lastAltitudes[i]=lastAltitudes[i+1];
					lastPositions[i]=lastPositions[i+1];
					lastTimes[i]=lastTimes[i+1];
				}
				
				//new value in
				lastAltitudes[MaxN-1]=alt;
				lastPositions[MaxN-1]=pos;
				lastTimes[MaxN-1]=time;
				
				//===========================================
				//after the arrays are ready we can check

				var newStatus = AscentStatus();
				//check if we are going up
				if(newStatus==0)
				{
					//not going up (enough)
					if(lastAscentStatus==0)
					{
						lastVal=-999;
					}
					else
					{
						//not going up anymore!
						//we should send an alert that the ascent is over
						//Att.playTone(TONE_DISTANCE_ALERT);
						lastAscentStatus = 0;
						lastVal=-99;
					}
				}
				else
				{
					//going up
					if(lastAscentStatus==0)
					{
						//first detection
						//Att.playTone(TONE_DISTANCE_ALERT);
						ascentElevationStart = lastAltitudes[0];
						ascentTimerStart = lastTimes[0];
						lastAscentStatus = 1;
					} 
					
					//computing the average speed so far
					var speed=(alt-ascentElevationStart)/(time-ascentTimerStart+0.01)/(3600.0*1000.0);
					lastVal=alt-ascentElevationStart;
				}
			}
		}

		return lastVal;
		
    }
    
    //returns 1 if currently going up (slope>threshold), 0 otherwise
    function AscentStatus() 
    {
    	//calculate the slope, todo: changing with the linear fit
		var ds = lastPositions[MaxN-1]-lastPositions[0];
		if(ds<0.01)
		{
			ds=0.01;
		}
		var slope=(lastAltitudes[MaxN-1]-lastAltitudes[0])/ds;
		
		if(slope>slopeThreshold)
		{
			return 1;
		}
		return 0;
    }

}