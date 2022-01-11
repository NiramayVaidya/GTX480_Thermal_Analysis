#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <cuda.h>

#define DEBUG 0

#define N 250

int matrixA[N][N], matrixB[N][N], matrixC[N][N], matrixD[N][N];

__global__ void mult_matrix(int matrixA[N][N], int matrixB[N][N], int matrixC[N][N]) {
	int i = blockDim.x*blockIdx.x + threadIdx.x;
	int j = blockDim.y*blockIdx.y + threadIdx.y;
    int k;

	if (i < N && j < N) {
        for (k = 0; k < N; k++) {
            matrixC[i][j] += matrixA[i][k] * matrixB[k][j];
        }
    }
}

int main() {
	int (*deviceA)[N];
	int (*deviceB)[N];
	int (*deviceC)[N];
	int i, j, k;
    
	for (i = 0; i < N; i++) {
		for (j = 0; j < N; j++) {
			matrixA[i][j] = rand() % 100;
			matrixB[i][j] = rand() % 100;
            matrixC[i][j] = 0;
            matrixD[i][j] = 0;
		}
	}
	
	cudaEvent_t start_time, stop_time;
	float elapsedTime;

	cudaMalloc((void **) &deviceA, N * N * sizeof(int));
	cudaMalloc((void **) &deviceB, N * N * sizeof(int));
	cudaMalloc((void **) &deviceC, N * N * sizeof(int));

	cudaMemcpy(deviceA, matrixA, N * N * sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(deviceB, matrixB, N * N * sizeof(int), cudaMemcpyHostToDevice);

	dim3 threadsPerBlock(32, 32);
	dim3 numOfBlocks(ceil(N / 32.0), ceil(N / 32.0));
	cudaEventCreate(&start_time);
	cudaEventRecord(start_time, 0);

	mult_matrix<<<numOfBlocks, threadsPerBlock>>>(deviceA, deviceB, deviceC);
	
	cudaEventCreate(&stop_time);
	cudaEventRecord(stop_time, 0);
	cudaEventSynchronize(stop_time);

	cudaEventElapsedTime(&elapsedTime, start_time, stop_time);
	cudaMemcpy(matrixC, deviceC, N * N * sizeof(int), cudaMemcpyDeviceToHost);
    
#if DEBUG
    printf("\nmatrixA-\n");
    for (i = 0; i < N; i++) {
		for (j = 0; j < N; j++) {
                printf("%d\t", matrixA[i][j]);
		}
		printf("\n");
	}
	
    printf("\nmatrixB-\n");
    for (i = 0; i < N; i++) {
		for (j = 0; j < N; j++) {
                printf("%d\t", matrixB[i][j]);
		}
		printf("\n");
	}
    
    printf("\nmatrixC-\n");
    for (i = 0; i < N; i++) {
		for (j = 0; j < N; j++) {
                printf("%d\t", matrixC[i][j]);
		}
		printf("\n");
	}
	printf("\n");
#endif
	
	printf("Parallely Elapsed Time: %f ms\n", elapsedTime);
	
	clock_t start_time_nonparallely, stop_time_nonparallely;
	start_time_nonparallely = clock();
    
	for (i = 0; i < N; i++) {
		for (j = 0; j < N; j++) {
            for (k = 0; k < N; k++) {
                matrixD[i][j] += matrixA[i][k] * matrixB[k][j];
            }
		}
	}
	
	stop_time_nonparallely = clock();
	printf("Non-parallely Elapsed Time: %f ms\n", (float) ((stop_time_nonparallely) - (start_time_nonparallely)));
	
	cudaFree(deviceA);
	cudaFree(deviceB);
	cudaFree(deviceC);
    
    return 0;
}
