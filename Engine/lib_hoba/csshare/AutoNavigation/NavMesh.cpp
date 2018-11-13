#include "NavMesh.h"
#include "HDetourNavMesh.h"
#include <stdio.h>
#include <string.h>
#include <assert.h>

CNavMesh::CNavMesh()
{
	m_dtNavMesh = 0;
}

CNavMesh::~CNavMesh()
{
	release();
}

void CNavMesh::release()
{
	if (m_dtNavMesh)
	{
		dtFreeNavMesh(m_dtNavMesh);
		m_dtNavMesh = 0;
	}
}

bool CNavMesh::load(const char* path)
{
	release();

	FILE* fp = fopen(path, "rb");
	if (!fp)
		return false;

	// Read header.
	NavMeshSetHeader header;
	size_t readLen = fread(&header, sizeof(NavMeshSetHeader), 1, fp);
	if (readLen != 1)
	{
		fclose(fp);
		return false;
	}
	if (header.magic != NAVMESHSET_MAGIC)
	{
		fclose(fp);
		return false;
	}
	if (header.version != NAVMESHSET_VERSION)
	{
		fclose(fp);
		return false;
	}

	m_dtNavMesh = dtAllocNavMesh();
	if (!m_dtNavMesh)
	{
		fclose(fp);
		return false;
	}
	dtStatus status = m_dtNavMesh->init(&header.params);
	if (dtStatusFailed(status))
	{
		release();
		fclose(fp);
		return false;
	}

	// Read tiles.
	for (int i = 0; i < header.numTiles; ++i)
	{
		NavMeshTileHeader tileHeader;
		readLen = fread(&tileHeader, sizeof(tileHeader), 1, fp);
		if (readLen != 1)
		{
			release();
			fclose(fp);
			return false;
		}

		if (!tileHeader.tileRef || !tileHeader.dataSize)
			break;

		unsigned char* data = (unsigned char*)dtAlloc(tileHeader.dataSize, DT_ALLOC_PERM);
		if (!data)
			break;
		memset(data, 0, tileHeader.dataSize);
		readLen = fread(data, tileHeader.dataSize, 1, fp);
		if (readLen != 1)
		{
			release();
			fclose(fp);
			return false;
		}

		m_dtNavMesh->addTile(data, tileHeader.dataSize, DT_TILE_FREE_DATA, tileHeader.tileRef, 0);
	}

	fclose(fp);

	return true;
}

bool CNavMesh::loadFromMemory(unsigned char* bytes, int numBytes)
{
	release();

	if (numBytes == 0)
		return false;

	int fPos = 0;
	const unsigned char* pBuffer = bytes;

	// Read header.
	if (numBytes - fPos < (int)sizeof(NavMeshSetHeader))
		return false;

	NavMeshSetHeader header;
	memcpy(&header, &pBuffer[fPos], sizeof(header));
	fPos += sizeof(header);

	if (header.magic != NAVMESHSET_MAGIC)
		return false;
	if (header.version != NAVMESHSET_VERSION)
		return false;

	m_dtNavMesh = dtAllocNavMesh();
	if (!m_dtNavMesh)
		return false;

	dtStatus status = m_dtNavMesh->init(&header.params);
	if (dtStatusFailed(status))
	{
		release();
		return false;
	}

	// Read tiles.
	for (int i = 0; i < header.numTiles; ++i)
	{
		NavMeshTileHeader tileHeader;

		//Read Tile Header
		if (numBytes - fPos < (int)sizeof(tileHeader))
		{
			release();
			return false;
		}
		memcpy(&tileHeader, &pBuffer[fPos], sizeof(tileHeader));
		fPos += sizeof(tileHeader);

		if (!tileHeader.tileRef || !tileHeader.dataSize)
			break;

		unsigned char* data = (unsigned char*)dtAlloc(tileHeader.dataSize, DT_ALLOC_PERM);
		if (!data)
			break;
		memset(data, 0, tileHeader.dataSize);

		//Read Tile Data
		if (numBytes - fPos < tileHeader.dataSize)
		{
			release();
			return false;
		}
		memcpy(data, &pBuffer[fPos], tileHeader.dataSize);
		fPos += tileHeader.dataSize;

		m_dtNavMesh->addTile(data, tileHeader.dataSize, DT_TILE_FREE_DATA, tileHeader.tileRef, 0);
	}

	return true;
}

void CNavMesh::getVertexIndexCount(int& vcount, int& icount, int areaId)
{
	if (!m_dtNavMesh)
	{
		vcount = 0;
		icount = 0;
		return;
	}

	int vnum = 0;
	int inum = 0;

	for (int iTile = 0; iTile < m_dtNavMesh->getMaxTiles(); ++iTile)
	{
		const dtMeshTile* tile = m_dtNavMesh->getTile(iTile);
		if (!tile->header)
			continue;

		dtPolyRef base = m_dtNavMesh->getPolyRefBase(tile);
		int tileNum = m_dtNavMesh->decodePolyIdTile(base);

		for (int i = 0; i < tile->header->polyCount; ++i)
		{
			const dtPoly* p = &tile->polys[i];
			if (p->getType() == DT_POLYTYPE_OFFMESH_CONNECTION)	// Skip off-mesh links.
				continue;

			if (p->getArea() != areaId)
				continue;

			const dtPolyDetail* pd = &tile->detailMeshes[i];

			vnum += pd->triCount * 3;
			inum += pd->triCount * 3;
		}
	}

	vcount = vnum;
	icount = inum;
}

void CNavMesh::fillVertexIndexBuffer(float vertices[], int vcount, int indices[], int icount, int areaId)
{
	int vnum = 0;
	int inum = 0;

	for (int iTile = 0; iTile < m_dtNavMesh->getMaxTiles(); ++iTile)
	{
		const dtMeshTile* tile = m_dtNavMesh->getTile(iTile);
		if (!tile->header)
			continue;

		dtPolyRef base = m_dtNavMesh->getPolyRefBase(tile);
		int tileNum = m_dtNavMesh->decodePolyIdTile(base);

		for (int i = 0; i < tile->header->polyCount; ++i)
		{
			const dtPoly* p = &tile->polys[i];
			if (p->getType() == DT_POLYTYPE_OFFMESH_CONNECTION)	// Skip off-mesh links.
				continue;

			if (p->getArea() != areaId)
				continue;

			const dtPolyDetail* pd = &tile->detailMeshes[i];

			for (int j = 0; j < pd->triCount; ++j)
			{
				const unsigned char* t = &tile->detailTris[(pd->triBase + j) * 4];
				for (int k = 0; k < 3; ++k)
				{
					float v[3];
					if (t[k] < p->vertCount)
					{
						memcpy(v, &tile->verts[p->verts[t[k]] * 3], sizeof(float) * 3);
					}
					else
					{
						memcpy(v, &tile->detailVerts[(pd->vertBase + t[k] - p->vertCount) * 3], sizeof(float) * 3);
					}

					vertices[vnum * 3 + 0] = v[0];
					vertices[vnum * 3 + 1] = v[1];
					vertices[vnum * 3 + 2] = v[2];

					++vnum;

					indices[inum] = vnum - 1;

					++inum;
				}
			}
		}
	}

	assert(vnum == vcount);
	assert(inum == icount);
}

bool CNavMesh::save(const char* path)
{
	if (!m_dtNavMesh)
		return false;

	FILE* fp = fopen(path, "wb");
	if (!fp)
		return false;

	// Store header.
	NavMeshSetHeader header;
	header.magic = NAVMESHSET_MAGIC;
	header.version = NAVMESHSET_VERSION;
	header.numTiles = 0;
	for (int i = 0; i < m_dtNavMesh->getMaxTiles(); ++i)
	{
		const dtMeshTile* tile = m_dtNavMesh->getTile(i);
		if (!tile || !tile->header || !tile->dataSize)
			continue;
		header.numTiles++;
	}
	memcpy(&header.params, m_dtNavMesh->getParams(), sizeof(dtNavMeshParams));
	fwrite(&header, sizeof(NavMeshSetHeader), 1, fp);

	// Store tiles.
	for (int i = 0; i < m_dtNavMesh->getMaxTiles(); ++i)
	{
		const dtMeshTile* tile = m_dtNavMesh->getTile(i);
		if (!tile || !tile->header || !tile->dataSize)
			continue;

		NavMeshTileHeader tileHeader;
		tileHeader.tileRef = m_dtNavMesh->getTileRef(tile);
		tileHeader.dataSize = tile->dataSize;
		fwrite(&tileHeader, sizeof(tileHeader), 1, fp);

		fwrite(tile->data, tile->dataSize, 1, fp);
	}

	fclose(fp);

	return true;
}