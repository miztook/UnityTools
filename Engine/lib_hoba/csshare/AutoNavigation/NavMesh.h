#ifndef _NAV_MESH_H_
#define _NAV_MESH_H_

#include "HDetourNavMesh.h"

using namespace HOBA;

static const int NAVMESHSET_MAGIC = 'M' << 24 | 'S' << 16 | 'E' << 8 | 'T'; //'MSET';
static const int NAVMESHSET_VERSION = 1;

struct NavMeshSetHeader
{
	int magic;
	int version;
	int numTiles;
	dtNavMeshParams params;
};

struct NavMeshTileHeader
{
	dtTileRef tileRef;
	int dataSize;
};

class CNavMesh
{
public:
	CNavMesh();
	~CNavMesh();

public:
	void setDtNavMesh(dtNavMesh* mesh) { m_dtNavMesh = mesh; }
	dtNavMesh* getDtNavMesh() const { return m_dtNavMesh; }

	void release();

	bool load(const char* path);
	bool save(const char* path);

	bool loadFromMemory(unsigned char* bytes, int numBytes);

	void getVertexIndexCount(int& vcount, int& icount, int areaId);
	void fillVertexIndexBuffer(float vertices[], int vcount, int indices[], int icount, int areaId);

private:
	dtNavMesh*		m_dtNavMesh;
};

#endif