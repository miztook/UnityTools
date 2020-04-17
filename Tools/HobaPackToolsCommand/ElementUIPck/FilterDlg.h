#pragma once

#include "resource.h"
#include <vector>

using pfnFilter = bool (WINAPI*)(const CString path, const CString name, bool bFolder);

class CPathTreeNode
{
public:
	CPathTreeNode(){};
	~CPathTreeNode()
	{
		for( int i = 0; i < (int)children.size(); ++i)
			delete children[i];
		children.clear();
	}

	void AddChild(CPathTreeNode* pChild)
	{
		if(pChild) 
			children.push_back(pChild);
	}
public:
	std::vector<CPathTreeNode* > children;
	CString text;
	BOOL    bCheck;
};

class CPathTree
{
public:
	CPathTree() { mRoot = 0; }
	~CPathTree() { if(mRoot) delete mRoot; }

	CPathTreeNode* InsertItem(CPathTreeNode *pParent, CString txt, BOOL bCheck);

	CPathTreeNode* GetRoot(){ return mRoot; }
private:
	CPathTreeNode* mRoot;
};

// CFilterDlg dialog

class CFilterDlg : public CDialog
{
	DECLARE_DYNAMIC(CFilterDlg)

	enum
	{
		ICON_MYCOMPUTER,
		ICON_FOLDER,
		ICON_OPENFOLDER,
		ICON_FILE,
	};

	enum
	{
		BFD_A = 0,
		BFD_B,
		BFD_HARDDISKBEGIN, 
		BFD_C = BFD_HARDDISKBEGIN,
		BFD_D,
		BFD_E,
		BFD_F,
		BFD_G,
		BFD_H,
		BFD_I,
		BFD_J,
		BFD_K,
		BFD_L,
		BFD_M,
		BFD_N,
		BFD_O,
		BFD_P,
		BFD_Q,
		BFD_R,
		BFD_S,
		BFD_T,
		BFD_U,
		BFD_V,
		BFD_W,
		BFD_X,
		BFD_Y,
		BFD_Z,
		BFD_MAX,
		BFD_FOLDER = BFD_MAX,
		BFD_FOLDER_OPENED,
		BFD_MYCOMPUTER,
		BFD_FILE,
	};

public:
	CFilterDlg(CWnd* pParent = NULL);   // standard constructor
	virtual ~CFilterDlg();

// Dialog Data
	enum { IDD = IDD_DIALOG_FILTER };

	void Init(const char* strInitPath, pfnFilter pfn = NULL){ m_strInitPath = strInitPath; m_pfn = pfn; }

	//检测路径是否被过滤器过滤掉了，如果被过滤掉返回TRUE
	//strPath:     这儿也是相对路径，如果是文件夹后面不要带"\\"
	bool IsFiltered(CString strPath);

	CTreeCtrl	m_PathTree;

protected:
	virtual void DoDataExchange(CDataExchange* pDX);    // DDX/DDV support

	DECLARE_MESSAGE_MAP()

	virtual BOOL OnInitDialog();
	virtual void OnOK();
	virtual void OnTimer(UINT_PTR nIDEvent);

	void		ReadPathTree(CString path, HTREEITEM hParent, int iCount, bool bInit = false, bool bOnlyFirst = false);
	CString		GetItemPath(HTREEITEM hItem);
	void        SetChildItemCheck( HTREEITEM hRoot, bool bCheck);
	void        SetParentItemCheck( HTREEITEM hChild, bool bCheck);
	void        BuildTreeEx();
	void        EnumTree(HTREEITEM hRoot,CPathTreeNode *pParent);
	HICON       GetShellIcon(int nindex); 
	HTREEITEM   GetInsertPos(HTREEITEM hParent,CString name, bool bFolder = true);

	afx_msg void OnItemexpandedTreeFilter(NMHDR* pNMHDR, LRESULT* pResult);
	afx_msg void OnClickTreeFilter(NMHDR* pNMHDR, LRESULT* pResult);
	afx_msg void OnSelectAll();
	afx_msg void OnSelectNone();

protected:
	CString         m_strInitPath;
	pfnFilter       m_pfn;

	CImageList		m_ImageList;
	CPathTree		m_PathTreeEx;
};
