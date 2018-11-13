#ifndef _CMD5_HASH_H_
#define _CMD5_HASH_H_

class CMd5Hash
{
public:
	CMd5Hash();

	static void Digest(const unsigned char * input, unsigned int inputlen,
		unsigned char output[16]);

	void update(const unsigned char* input, unsigned int inputlen);
	void final(unsigned char output[16]);

	static bool getString(const unsigned char digest[16], char* buffer, unsigned int length);

	static bool DigestString(const unsigned char * input, unsigned int inputlen, char* buffer, unsigned int length);

private:
	void transform(const unsigned char block[64]);

private:
	unsigned int state[4];
	unsigned int count[2];
	unsigned char buffer[64];
};

#endif