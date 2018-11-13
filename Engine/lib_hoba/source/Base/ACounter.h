#pragma once

#include "ATypes.h"

class ACounter
{
public:		//	Types

public:		//	Constructor and Destructor

	ACounter()
	{
		m_dwCounter = 0;
		m_dwPeriod = 0;
		m_bPause = false;
	}

public:		//	Attributes

public:		//	Operations

	//	Set / Get period
	void SetPeriod(auint32 dwPeriod) { m_dwPeriod = dwPeriod; }
	auint32 GetPeriod() const { return m_dwPeriod; }
	//	Set / Get counter
	void SetCounter(auint32 dwCounter) { m_dwCounter = dwCounter; }
	auint32 GetCounter() const { return m_dwCounter; }

	//	Has counter reached period ?
	bool IsFull() const { return m_dwCounter >= m_dwPeriod; }
	//	Reset counter
	void Reset(bool bFull = false) { m_dwCounter = bFull ? m_dwPeriod : 0; }
	//	Set pause flag
	void SetPause(bool bPause) { m_bPause = bPause; }
	bool IsPause() { return m_bPause; }

	//	Increase counter
	bool IncCounter(auint32 dwCounter)
	{
		if (!m_bPause)
			m_dwCounter += dwCounter;
		return (m_dwCounter >= m_dwPeriod) ? true : false;
	}

	//	Decrease counter
	void DecCounter(auint32 dwCounter)
	{
		if (m_bPause)
			return;

		if (m_dwCounter <= dwCounter)
			m_dwCounter = 0;
		else
			m_dwCounter -= dwCounter;
	}

protected:	//	Attributes

	auint32	m_dwCounter;		//	Counter
	auint32	m_dwPeriod;			//	Count period
	bool	m_bPause;			//	Pause flag
};