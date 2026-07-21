#pragma once
#include<math.h>
/// <summary>
/// 时钟同步类型
/// </summary>
typedef enum
{
	// 同步到音频
	CLOCKSYNCTYPE_AUDIO,
	// 同步到视频
	CLOCKSYNCTYPE_VIDEO,
	// 同步到绝对时钟
	CLOCKSYNCTYPE_ABSOLUTE
} ClockSyncType;

class Clock
{
public:
	bool isDisabled = false;
	// 起始时间
	//double startTime=0;
	// 当前pts
	double startPts=NAN;
	// 当前pts
	double currentPts = NAN;
	double getTime();
	void updatePts(double pts);

};

class ClockSync
{
public:
	void reset();
	Clock* getMasterClock();
	//double getMasterTime();
	double calVideoDelay(double pts, double duration);
	double calAudioDelay(double pts, double duration);
	void updateVideoPts(double pts);
	void updateAudioPts(double pts);
	ClockSyncType type;
	Clock audio;
	Clock video;
	Clock absolute;
private:
	/// <summary>
/// 音频时钟
/// </summary>

	double estimateVideoDuration{ 0 };
	double n{0};
};

