from astropy.io import fits
from scipy import ndimage
import scipy.optimize as optimize
import time
import numpy as np
from astropy.stats import sigma_clipped_stats

def get_ref_wcs(argv, Number_of_files):
    F_re_x_min = np.inf
    F_re_y_min = np.inf
    F_re_x_max = -np.inf
    F_re_y_max = -np.inf
    directory = argv[1]+'/'
    for i in range(Number_of_files):
        F_re_x_min = min(F_re_x_min, get_wcs(directory + argv[i + 2])[3])
        F_re_y_min = min(F_re_y_min, get_wcs(directory + argv[i + 2])[4])
        F_re_x_max = max(F_re_x_max, get_wcs(directory + argv[i + 2])[5])
        F_re_y_max = max(F_re_y_max, get_wcs(directory + argv[i + 2])[6])
    return F_re_x_min, F_re_y_min, F_re_x_max, F_re_y_max


def get_ref_fitting(argv, Number_of_files, pixel_size):
    directory = argv[1]+'/'
    reference = np.array([0, 0])
    data0 = fits.getdata(directory + argv[2])
    data0 = grouped_Avg(data0, data0.shape[2])[:, :, -1]
    max_index0_1 = get_po(directory+"config", argv[2])[0]
    max_index0_2 = get_po(directory+"config", argv[2])[1]
    max_index0 = (max_index0_2-1, max_index0_1-1)
    max_value0 = get_po(directory+"config", argv[2])[2]
    for i in range(Number_of_files-1):
        datai = fits.getdata(directory+argv[i+3])
        datai = grouped_Avg(datai, datai.shape[2])[:, :, -1]
        max_indexi_1 = get_po(directory+"config", argv[i+3])[0]
        max_indexi_2 = get_po(directory+"config", argv[i+3])[1]
        max_indexi = (max_indexi_2 - 1, max_indexi_1 - 1)
        max_valuei = get_po(directory+"config", argv[i+3])[2]
        diff_x = max_indexi[1] - max_index0[1]
        diff_y = max_indexi[0] - max_index0[0]
        ratio = max_valuei/max_value0
        initial_guess = np.array([diff_x, diff_y, ratio])
        res = optimize.minimize(total_chi2, initial_guess, method="Nelder-Mead", args=(data0, datai), tol=1e-6)
        reference = np.append(reference, -1*res.x[:-1])
    reference = reference.reshape(Number_of_files, 2)
    reference[:, 0] = reference[:, 0] - np.amin(reference[:, 0])
    reference[:, 1] = reference[:, 1] - np.amin(reference[:, 1])
    reference = reference * pixel_size
    top_right_x = np.amax(reference[:, 0])
    top_right_y = np.amax(reference[:, 1])
    top_right_x = top_right_x + data0.shape[1] * pixel_size
    top_right_y = top_right_y + data0.shape[0] * pixel_size
    print(reference)
    return reference, top_right_x, top_right_y


def get_ref_input(argv, Number_of_files, pixel_size):
    directory = argv[1]+'/'
    reference = np.array([])
    shape = fits.getdata(directory + argv[2]).shape[:-1]
    print(shape)
    for i in range(Number_of_files):
        index = get_po_input(directory+"config_input", argv[i+2])
        reference = np.append(reference, index)
    reference = reference.reshape(Number_of_files, 2)
    reference[:, 0] = reference[:, 0] - np.amin(reference[:, 0])
    reference[:, 1] = reference[:, 1] - np.amin(reference[:, 1])
    top_right_x = np.amax(reference[:, 0])
    top_right_y = np.amax(reference[:, 1])
    top_right_x = top_right_x + shape[1] * pixel_size
    top_right_y = top_right_y + shape[0] * pixel_size
    #print(top_right_y, top_right_x)
    #print(reference)
    return reference, top_right_x, top_right_y


def total_chi2(w, data0, datai):
    diff_x, diff_y, ratio = w
    data0_new = ndimage.shift(data0, [diff_y, diff_x])
    total = np.sum((data0_new*ratio-datai)**2)
    return total


def grouped_Avg(myArray, N=10):
    if myArray.shape[2] < N:
        raise ValueError('stacking number must be smaller than the number of channel')
    elif N <= 0:
        raise ValueError('stacking number must be larger than 0')
    else:
        cum = np.cumsum(myArray, 2)
        result = cum[:, :, N - 1::N] / float(N)
        result[:, :, 1:] = result[:, :, 1:] - result[:, :, :-1]
        remainder = myArray.shape[2] % N
        if remainder != 0:
            lastAvg = (cum[:, :, -1] - cum[:, :, -1 - remainder]) / float(remainder)
            result = np.concatenate([result, lastAvg[:, :, None]], axis=2)
        return result


def grouped_sum(myArray, N=10):
    if myArray.shape[2] < N:
        raise ValueError('stacking number must be smaller than the number of channel')
    elif N <= 0:
        raise ValueError('stacking number must be larger than 0')
    else:
        cum = np.cumsum(myArray, 2)
        result = cum[:, :, N - 1::N]
        result[:, :, 1:] = result[:, :, 1:] - result[:, :, :-1]
        remainder = myArray.shape[2] % N
        if remainder != 0:
            lastAvg = (cum[:, :, -1] - cum[:, :, -1 - remainder])
            result = np.concatenate([result, lastAvg[:, :, None]], axis=2)
        return result


def grouped_Median(myArray, N=10):
    result = np.zeros((myArray.shape[0], myArray.shape[1]))
    result = [result.tolist()]
    if myArray.shape[2] < N:
        raise ValueError('stacking number must be smaller than the number of channel')
    elif N<=0:
        raise ValueError('stacking number must be larger than 0')
    else:
        for i in range(int(myArray.shape[2]/N)):
            myArray_perchannel = np.median(myArray[:, :, N*i:N*(i+1)], axis=2)
            result.append(myArray_perchannel.tolist())
        result = np.asarray(result)
        result = np.swapaxes(result, 0, 1)
        result = np.swapaxes(result, 1, 2)[:, :, 1:]  # get rid of the first zero 2D array
        # need to include the remainder

        remainder = myArray.shape[2] % N
        if remainder != 0:
            lastMedian = np.median(myArray[:, :, -remainder:myArray.shape[2]],axis=2)
            result = np.concatenate([result, lastMedian[:, :, None]], axis=2)
        return result


def get_wcs(file):  ## return the dim_x, dim_y, bottomleft_x, bottomleft_y, topright_x, topright_y of input file
    hdul = fits.open(file)
    x_coord = hdul[0].header['CRVAL2']*3600     # the real coord of reference x in arcsec
    y_coord = hdul[0].header['CRVAL3']*3600     # the real coord of reference y in arcsec
    x_re_pix = hdul[0].header['CRPIX2']         # reference x pixel index
    y_re_pix = hdul[0].header['CRPIX3']         # reference y pixel index
    pixel_size = hdul[0].header['CDELT2']*3600
    bottomleft_x = x_coord - x_re_pix * pixel_size + 0.5 * pixel_size
    bottomleft_y = y_coord - y_re_pix * pixel_size + 0.5 * pixel_size
    dim_y, dim_x, dim_z = hdul[0].data.shape
    topright_x = bottomleft_x + dim_x*pixel_size
    topright_y = bottomleft_y + dim_y*pixel_size
    return pixel_size, dim_x, dim_y, bottomleft_x, bottomleft_y, topright_x, topright_y, dim_z


def get_po(input_file, key_word):
    with open(input_file) as openfile:
        for line in openfile:
            counter = 0
            for part in line.split():
                counter = counter + 1
                if key_word in part:
                    return float(line.split()[counter]), float(line.split()[counter + 1]), float(
                        line.split()[counter + 2])


def get_po_input(input_file, key_word):
    with open(input_file) as openfile:
        for line in openfile:
            counter = 0
            for part in line.split():
                counter = counter + 1
                if key_word in part:
                    return float(line.split()[counter]), float(line.split()[counter + 1])


def drizzle_matrix_fast(d_drizzle, d_fine, Input_dim_x, Input_dim_y, X_org, Y_org, dim_x_fine, dim_y_fine, X_fine, Y_fine):
    start = time.time()
    b_min = abs(d_fine - d_drizzle) / 2
    b_max = (d_fine + d_drizzle) / 2
    mask_x0_c1 = b_min < abs(X_org[..., None] - X_fine.ravel()[None, None,:])  # the condition that the distance of two x is larger than b_min
    mask_x0_c2 = abs(X_org[..., None] - X_fine.ravel()[None, None,:]) < b_max  # the condition that the distance of two points is smaller than b_max

    weight_x0 = (-abs(X_org[..., None] - X_fine.ravel()[None, None, :]) + b_max) * mask_x0_c1 * mask_x0_c2 / d_drizzle
    mask_x1 = abs(X_org[..., None] - X_fine.ravel()[None, None,:]) <= b_min  # the condition that the distance of two x is smaller than b_min

    if d_drizzle <= d_fine:
        weight_x1 = np.ones((Input_dim_y, Input_dim_x, dim_y_fine * dim_x_fine)) * mask_x1  # the weight match the above condition
    else:
        weight_x1 = np.ones((Input_dim_y, Input_dim_x, dim_y_fine * dim_x_fine)) * mask_x1 * d_fine / d_drizzle

    mask_y0_c1 = b_min < abs(Y_org[..., None] - Y_fine.ravel()[None, None, :])  # same for y
    mask_y0_c2 = abs(Y_org[..., None] - Y_fine.ravel()[None, None, :]) < b_max

    weight_y0 = (-abs(Y_org[..., None] - Y_fine.ravel()[None, None, :]) + b_max) * mask_y0_c1 * mask_y0_c2 / d_drizzle
    mask_y1 = abs(Y_org[..., None] - Y_fine.ravel()[None, None, :]) <= b_min
    if d_drizzle <= d_fine:
        weight_y1 = np.ones((Input_dim_y, Input_dim_x, dim_y_fine * dim_x_fine)) * mask_y1
    else:
        weight_y1 = np.ones((Input_dim_y, Input_dim_x, dim_y_fine * dim_x_fine)) * mask_y1 * d_fine / d_drizzle
    total = weight_x0 * weight_y0 + weight_x0 * weight_y1 + weight_x1 * weight_y0 + weight_x1 * weight_y1
    w = np.swapaxes(total, 1, 2)
    final = np.swapaxes(w, 0, 1).ravel().reshape(dim_y_fine * dim_x_fine, Input_dim_y * Input_dim_x)
    end = time.time()
    print("time for creating the mapping matrix", round(end-start, 2))
    print(final.shape)
    return np.asmatrix(final)


def combine_frames_wcs(argv, d_orig, d_drizzle, d_fine, F_re_y_min, F_re_y_max, F_re_x_min, F_re_x_max):
    final_image = 0
    final_weight = 0
    directory = argv[1]+"/"
    stacking_N = float(argv[-3])
    combine_type = float(argv[-2])
    Number_of_files = len(argv) - 7
    print(Number_of_files, "frames need to be drizzled")
    for i in range(Number_of_files):
        start = time.time()
        # input file coordinate
        # the dimension of the input file
        Input_dim_x = get_wcs(directory + argv[i + 2])[1]
        Input_dim_y = get_wcs(directory + argv[i + 2])[2]
        # the reference point of the most bottom left pixel of the input file
        Input_re_x_min = get_wcs(directory + argv[i + 2])[3]
        Input_re_y_min = get_wcs(directory + argv[i + 2])[4]
        # the reference point of the most top right pixel of the input file
        Input_re_x_max = Input_re_x_min + Input_dim_x * d_orig
        Input_re_y_max = Input_re_y_min + Input_dim_y * d_orig
        # create the array of the input file
        Y_org, X_org = np.mgrid[Input_re_y_min:Input_re_y_max:d_orig, Input_re_x_min:Input_re_x_max:d_orig]
        if Y_org.shape[0] != Input_dim_y:
            Y_org = Y_org[:-1, :]
            X_org = X_org[:-1, :]
            print("warning: correcting the size of input files")
        if Y_org.shape[1] != Input_dim_x:
            Y_org = Y_org[:, :-1]
            X_org = X_org[:, :-1]
        Y_org, X_org = Y_org + d_orig / 2, X_org + d_orig / 2
        # create the array of the fine grid
        Y_fine, X_fine = np.mgrid[F_re_y_min - d_fine:F_re_y_max + d_fine:d_fine,
                         F_re_x_min - d_fine:F_re_x_max + d_fine:d_fine]
        Y_fine, X_fine = Y_fine + d_fine / 2, X_fine + d_fine / 2
        dim_y_fine, dim_x_fine = Y_fine.shape
        startM = time.time()
        # obtain the 2D matrix which maps source plan to imaging plan.
        M = drizzle_matrix_fast(d_drizzle, d_fine, Input_dim_x, Input_dim_y, X_org, Y_org, dim_x_fine, dim_y_fine,
                                X_fine, Y_fine)
        endM = time.time()
        print(M.shape)
        print("time for creating matrix", round(endM - startM, 2), "seconds")
        per_weight = M*np.asmatrix(np.ones((M.shape[1], 1))) ## create the weight imaging
        final_weight = final_weight + per_weight.reshape(dim_y_fine, dim_x_fine)

        total_channels = np.zeros((dim_y_fine, dim_x_fine))
        total_channels = [total_channels.tolist()]  # change to 3D list data structure
        cube = fits.getdata(directory + argv[i + 2])
        if combine_type == -1 and stacking_N == -1:
            cube_new = grouped_Avg(cube, N=10)
        elif combine_type != -1 and stacking_N == -1:
            if combine_type == 1:
                cube_new = grouped_Avg(cube, N=10)
            elif combine_type == 2:
                cube_new = grouped_Median(cube, N=10)
            else:
                raise ValueError('-1 = default (average); 1 = average; 2 = median')
        elif combine_type == -1 and stacking_N != -1:
            cube_new = grouped_Avg(cube, N=int(stacking_N))
        else:
            if combine_type == 1:
                cube_new = grouped_Avg(cube, N=int(stacking_N))
            elif combine_type == 2:
                cube_new = grouped_Median(cube, N=int(stacking_N))
            else:
                raise ValueError('-1 = default (average); 1 = average; 2 = median')
        for j in range(cube_new.shape[2]):
            source = cube_new[:, :, j]
            source_matrix = np.asmatrix(source.ravel())
            per_channel = M * source_matrix.T
            per_channel = per_channel.reshape(dim_y_fine, dim_x_fine)
            total_channels.append(per_channel.tolist())  # list is much faster than array when using append
        total_channels = np.asarray(total_channels)
        total_channels = np.swapaxes(total_channels, 0, 1)
        total_channels = np.swapaxes(total_channels, 1, 2)
        final_image = final_image + total_channels[:, :, 1:]  # get rid of the first zeros
        end = time.time()
        print("time for drizzling number %d frame" % (i + 1), round(end - start, 2), "seconds")
        # print(final_image.shape)
    return final_image, final_weight


def combine_frames_findpo(argv, d_orig, d_drizzle, d_fine, reference_po, F_re_y_min, F_re_y_max, F_re_x_min, F_re_x_max):
    final_image = 0
    final_weight = 0
    directory = argv[1]+'/'
    stacking_N = float(argv[-3])
    combine_type = float(argv[-2])
    Number_of_files = len(argv) - 7
    print(Number_of_files, "frames need to be drizzled")
    for i in range(Number_of_files):
        start = time.time()
        # input file coordinate
        # the dimension of the input file
        Input_dim_x = get_wcs(directory + argv[i + 2])[1]
        Input_dim_y = get_wcs(directory + argv[i + 2])[2]
        # the reference point of the most bottom left pixel of the input file

        Input_re_x_min = reference_po[i, 0]
        Input_re_y_min = reference_po[i, 1]
        # the reference point of the most top right pixel of the input file
        Input_re_x_max = Input_re_x_min + Input_dim_x * d_orig
        Input_re_y_max = Input_re_y_min + Input_dim_y * d_orig
        # create the array of the input file
        Y_org, X_org = np.mgrid[Input_re_y_min:Input_re_y_max:d_orig, Input_re_x_min:Input_re_x_max:d_orig]
        if Y_org.shape[0] != Input_dim_y:
            Y_org = Y_org[:-1, :]
            X_org = X_org[:-1, :]
            print("warning: correcting the size of input files")
        if Y_org.shape[1] != Input_dim_x:
            Y_org = Y_org[:, :-1]
            X_org = X_org[:, :-1]
        Y_org, X_org = Y_org + d_orig / 2, X_org + d_orig / 2
        # create the array of the fine grid
        Y_fine, X_fine = np.mgrid[F_re_y_min - d_fine:F_re_y_max + d_fine:d_fine,
                         F_re_x_min - d_fine:F_re_x_max + d_fine:d_fine]
        Y_fine, X_fine = Y_fine + d_fine / 2, X_fine + d_fine / 2
        dim_y_fine, dim_x_fine = Y_fine.shape

        # obtain the 2D matrix which maps source plan to imaging plan.
        M = drizzle_matrix_fast(d_drizzle, d_fine, Input_dim_x, Input_dim_y, X_org, Y_org, dim_x_fine, dim_y_fine,
                                X_fine, Y_fine)

        per_weight = M*np.asmatrix(np.ones((M.shape[1], 1))) ## create the weight imaging
        final_weight = final_weight + per_weight.reshape(dim_y_fine, dim_x_fine)

        total_channels = np.zeros((dim_y_fine, dim_x_fine))
        total_channels = [total_channels.tolist()]  # change to 3D list data structure
        cube = fits.getdata(directory + argv[i + 2])
        if combine_type == -1 and stacking_N == -1:
            cube_new = grouped_Avg(cube, N=10)
        elif combine_type != -1 and stacking_N == -1:
            if combine_type == 1:
                cube_new = grouped_Avg(cube, N=10)
            elif combine_type == 2:
                cube_new = grouped_Median(cube, N=10)
            else:
                raise ValueError('-1 = default (average); 1 = average; 2 = median')
        elif combine_type == -1 and stacking_N != -1:
            cube_new = grouped_Avg(cube, N=int(stacking_N))
        else:
            if combine_type == 1:
                cube_new = grouped_Avg(cube, N=int(stacking_N))
            elif combine_type == 2:
                cube_new = grouped_Median(cube, N=int(stacking_N))
            else:
                raise ValueError('-1 = default (average); 1 = average; 2 = median')
        for j in range(cube_new.shape[2]):
            source = cube_new[:, :, j]
            source[source < -100] = 0
            source_matrix = np.asmatrix(source.ravel())
            per_channel = M * source_matrix.T
            per_channel = per_channel.reshape(dim_y_fine, dim_x_fine)
            total_channels.append(per_channel.tolist())  # list is much faster than array when using append

        total_channels = np.asarray(total_channels)
        total_channels = np.swapaxes(total_channels, 0, 1)
        total_channels = np.swapaxes(total_channels, 1, 2)
        final_image = final_image + total_channels[:, :, 1:]  # get rid of the first zeros
        end = time.time()
        print("time for drizzling number %d frame" % (i + 1), round(end - start, 2), "seconds")
    return final_image, final_weight


def combine_frames_wcs_correct(argv, d_orig, d_drizzle, d_fine, F_re_y_min, F_re_y_max, F_re_x_min, F_re_x_max):
    final_image = 0
    final_weight = 0
    final_cover = 0
    directory = argv[1]+"/"
    stacking_N = float(argv[-3])
    combine_type = float(argv[-2])
    Number_of_files = len(argv) - 7
    print(Number_of_files, "frames need to be drizzled")
    for i in range(Number_of_files):
        start = time.time()
        # input file coordinate
        # the dimension of the input file
        Input_dim_x = get_wcs(directory + argv[i + 2])[1]
        Input_dim_y = get_wcs(directory + argv[i + 2])[2]
        # the reference point of the most bottom left pixel of the input file
        Input_re_x_min = get_wcs(directory + argv[i + 2])[3]
        Input_re_y_min = get_wcs(directory + argv[i + 2])[4]
        # the reference point of the most top right pixel of the input file
        Input_re_x_max = Input_re_x_min + Input_dim_x * d_orig
        Input_re_y_max = Input_re_y_min + Input_dim_y * d_orig
        # create the array of the input file
        Y_org, X_org = np.mgrid[Input_re_y_min:Input_re_y_max:d_orig, Input_re_x_min:Input_re_x_max:d_orig]
        if Y_org.shape[0] != Input_dim_y:
            Y_org = Y_org[:-1, :]
            X_org = X_org[:-1, :]
            print("warning: correcting the size of input files")
        if Y_org.shape[1] != Input_dim_x:
            Y_org = Y_org[:, :-1]
            X_org = X_org[:, :-1]
        Y_org, X_org = Y_org + d_orig / 2, X_org + d_orig / 2
        # create the array of the fine grid
        Y_fine, X_fine = np.mgrid[F_re_y_min - d_fine:F_re_y_max + d_fine:d_fine,
                         F_re_x_min - d_fine:F_re_x_max + d_fine:d_fine]
        Y_fine, X_fine = Y_fine + d_fine / 2, X_fine + d_fine / 2
        dim_y_fine, dim_x_fine = Y_fine.shape

        # obtain the 2D matrix which maps source plan to imaging plan.
        M = drizzle_matrix_fast(d_drizzle, d_fine, Input_dim_x, Input_dim_y, X_org, Y_org, dim_x_fine, dim_y_fine,
                                X_fine, Y_fine)
        per_cover = M*np.asmatrix(np.ones((M.shape[1], 1))) ## create the weight imaging
        final_cover = final_cover + per_cover.reshape(dim_y_fine, dim_x_fine)

        total_channels = np.zeros((dim_y_fine, dim_x_fine))
        total_channels = [total_channels.tolist()]  # change to 3D list data structure
        total_channels_weight = np.zeros((dim_y_fine, dim_x_fine))
        total_channels_weight = [total_channels_weight.tolist()]
        cube = fits.getdata(directory + argv[i + 2])
        cube_noise = fits.open(directory + argv[i + 2])[1].data
        cube_noise[cube_noise == 0] = np.inf  # set no weight info to infinity noise
        cube_weight = 1/cube_noise**2  # take the noise map into weight map
        if combine_type == -1 and stacking_N == -1:
            cube_new = grouped_Avg(cube, N=10)
            cube_weight_new = grouped_sum(cube_weight, N=10)
        elif combine_type != -1 and stacking_N == -1:
            if combine_type == 1:
                cube_new = grouped_Avg(cube, N=10)
                cube_weight_new = grouped_sum(cube_weight, N=10)
            elif combine_type == 2:
                cube_new = grouped_Median(cube, N=10)
                cube_weight_new = grouped_sum(cube_weight, N=10)
            else:
                raise ValueError('-1 = default (average); 1 = average; 2 = median')
        elif combine_type == -1 and stacking_N != -1:
            cube_new = grouped_Avg(cube, N=int(stacking_N))
            cube_weight_new = grouped_sum(cube_weight, N=int(stacking_N))
        else:
            if combine_type == 1:
                cube_new = grouped_Avg(cube, N=int(stacking_N))
                cube_weight_new = grouped_sum(cube_weight, N=int(stacking_N))
            elif combine_type == 2:
                cube_new = grouped_Median(cube, N=int(stacking_N))
                cube_weight_new = grouped_sum(cube_weight, N=int(stacking_N))
            else:
                raise ValueError('-1 = default (average); 1 = average; 2 = median')
        for j in range(cube_new.shape[2]):
            source = cube_new[:, :, j]
            source_weight = cube_weight_new[:, :, j]
            source_matrix = np.asmatrix(source.ravel())
            source_weight_matrix = np.asmatrix(source_weight.ravel())
            per_channel = M * source_matrix.T
            per_channel_weight = M * source_weight_matrix.T
            per_channel = per_channel.reshape(dim_y_fine, dim_x_fine)
            per_channel_weight = per_channel_weight.reshape(dim_y_fine, dim_x_fine)
            total_channels.append(per_channel.tolist())  # list is much faster than array when using append
            total_channels_weight.append(per_channel_weight.tolist())
        total_channels = np.asarray(total_channels)
        total_channels = np.swapaxes(total_channels, 0, 1)
        total_channels = np.swapaxes(total_channels, 1, 2)
        total_channels_weight = np.asarray(total_channels_weight)
        total_channels_weight = np.swapaxes(total_channels_weight, 0, 1)
        total_channels_weight = np.swapaxes(total_channels_weight, 1, 2)
        end = time.time()
        print("time for drizzling number %d frame" % (i + 1), round(end - start, 2), "seconds")
        final_image = final_image * final_weight + total_channels[:, :, 1:]*total_channels_weight[:, :, 1:]  # get rid of the first zeros
        final_weight = final_weight + total_channels_weight[:, :, 1:]
        final_weight_setinf = np.copy(final_weight)  # for getting rid of Nan in the output final_image
        final_weight_setinf[final_weight_setinf == 0] = np.inf
        final_image = final_image/final_weight_setinf
    return final_image, final_cover, final_weight


def combine_frames_findpo_correct(argv, d_orig, d_drizzle, d_fine, reference_po, F_re_y_min, F_re_y_max, F_re_x_min, F_re_x_max):
    final_image = 0
    final_weight = 0
    final_cover = 0
    directory = argv[1]+'/'
    stacking_N = float(argv[-3])
    combine_type = float(argv[-2])
    Number_of_files = len(argv) - 7
    print(Number_of_files, "frames need to be drizzled")
    for i in range(Number_of_files):
        start = time.time()
        # input file coordinate
        # the dimension of the input file
        Input_dim_x = get_wcs(directory + argv[i + 2])[1]
        Input_dim_y = get_wcs(directory + argv[i + 2])[2]
        # the reference point of the most bottom left pixel of the input file

        Input_re_x_min = reference_po[i, 0]
        Input_re_y_min = reference_po[i, 1]
        # the reference point of the most top right pixel of the input file
        Input_re_x_max = Input_re_x_min + Input_dim_x * d_orig
        Input_re_y_max = Input_re_y_min + Input_dim_y * d_orig
        # create the array of the input file
        Y_org, X_org = np.mgrid[Input_re_y_min:Input_re_y_max:d_orig, Input_re_x_min:Input_re_x_max:d_orig]
        if Y_org.shape[0] != Input_dim_y:
            Y_org = Y_org[:-1, :]
            X_org = X_org[:-1, :]
            print("warning: correcting the size of input files")
        if Y_org.shape[1] != Input_dim_x:
            Y_org = Y_org[:, :-1]
            X_org = X_org[:, :-1]
        Y_org, X_org = Y_org + d_orig / 2, X_org + d_orig / 2
        # create the array of the fine grid
        Y_fine, X_fine = np.mgrid[F_re_y_min - d_fine:F_re_y_max + d_fine:d_fine,
                         F_re_x_min - d_fine:F_re_x_max + d_fine:d_fine]
        Y_fine, X_fine = Y_fine + d_fine / 2, X_fine + d_fine / 2
        dim_y_fine, dim_x_fine = Y_fine.shape

        # obtain the 2D matrix which maps source plan to imaging plan.
        M = drizzle_matrix_fast(d_drizzle, d_fine, Input_dim_x, Input_dim_y, X_org, Y_org, dim_x_fine, dim_y_fine,
                                X_fine, Y_fine)

        per_cover = M*np.asmatrix(np.ones((M.shape[1], 1))) ## create the weight imaging
        final_cover = final_cover + per_cover.reshape(dim_y_fine, dim_x_fine)

        total_channels = np.zeros((dim_y_fine, dim_x_fine))
        total_channels_weight = np.zeros((dim_y_fine, dim_x_fine))
        total_channels_weight = [total_channels_weight.tolist()]
        total_channels = [total_channels.tolist()]  # change to 3D list data structure
        cube = fits.getdata(directory + argv[i + 2])
        cube_noise = fits.open(directory + argv[i + 2])[1].data
        cube_noise[cube_noise == 0] = np.inf  # set no weight info to infinity noise
        cube_weight = 1/cube_noise**2  # take the noise map into weight map
        if combine_type == -1 and stacking_N == -1:
            cube_new = grouped_Avg(cube, N=10)
            cube_weight_new = grouped_sum(cube_weight, N=10)
        elif combine_type != -1 and stacking_N == -1:
            if combine_type == 1:
                cube_new = grouped_Avg(cube, N=10)
                cube_weight_new = grouped_sum(cube_weight, N=10)
            elif combine_type == 2:
                cube_new = grouped_Median(cube, N=10)
                cube_weight_new = grouped_sum(cube_weight, N=10)
            else:
                raise ValueError('-1 = default (average); 1 = average; 2 = median')
        elif combine_type == -1 and stacking_N != -1:
            cube_new = grouped_Avg(cube, N=int(stacking_N))
            cube_weight_new = grouped_sum(cube_weight, N=int(stacking_N))
        else:
            if combine_type == 1:
                cube_new = grouped_Avg(cube, N=int(stacking_N))
                cube_weight_new = grouped_sum(cube_weight, N=int(stacking_N))
            elif combine_type == 2:
                cube_new = grouped_Median(cube, N=int(stacking_N))
                cube_weight_new = grouped_sum(cube_weight, N=int(stacking_N))
            else:
                raise ValueError('-1 = default (average); 1 = average; 2 = median')
        for j in range(cube_new.shape[2]):
            source = cube_new[:, :, j]
            source_weight = cube_weight_new[:, :, j]
            source_matrix = np.asmatrix(source.ravel())
            source_weight_matrix = np.asmatrix(source_weight.ravel())
            per_channel = M * source_matrix.T
            per_channel_weight = M * source_weight_matrix.T
            per_channel = per_channel.reshape(dim_y_fine, dim_x_fine)
            per_channel_weight = per_channel_weight.reshape(dim_y_fine, dim_x_fine)
            total_channels.append(per_channel.tolist())  # list is much faster than array when using append
            total_channels_weight.append(per_channel_weight.tolist())

        total_channels = np.asarray(total_channels)
        total_channels = np.swapaxes(total_channels, 0, 1)
        total_channels = np.swapaxes(total_channels, 1, 2)
        total_channels_weight = np.asarray(total_channels_weight)
        total_channels_weight = np.swapaxes(total_channels_weight, 0, 1)
        total_channels_weight = np.swapaxes(total_channels_weight, 1, 2)
        end = time.time()
        print("time for drizzling number %d frame" % (i + 1), round(end - start, 2), "seconds")
        final_image = final_image * final_weight + total_channels[:, :, 1:]*total_channels_weight[:, :, 1:]  # get rid of the first zeros
        final_weight = final_weight + total_channels_weight[:, :, 1:]
        final_weight_setinf = np.copy(final_weight)  # for getting rid of Nan in the output final_image
        final_weight_setinf[final_weight_setinf == 0] = np.inf
        final_image = final_image/final_weight_setinf
    return final_image, final_cover, final_weight


def combine_noise_findpo(argv, d_orig, d_drizzle, d_fine, reference_po, F_re_y_min, F_re_y_max, F_re_x_min, F_re_x_max):
    final_noise = 0
    directory = argv[1]+'/'
    stacking_N = float(argv[-3])
    combine_type = float(argv[-2])
    Number_of_files = len(argv) - 7
    print(Number_of_files, "frames need to be drizzled")
    for i in range(Number_of_files):
        start = time.time()
        # input file coordinate
        # the dimension of the input file
        Input_dim_x = get_wcs(directory + argv[i + 2])[1]
        Input_dim_y = get_wcs(directory + argv[i + 2])[2]
        # the reference point of the most bottom left pixel of the input file

        Input_re_x_min = reference_po[i, 0]
        Input_re_y_min = reference_po[i, 1]
        # the reference point of the most top right pixel of the input file
        Input_re_x_max = Input_re_x_min + Input_dim_x * d_orig
        Input_re_y_max = Input_re_y_min + Input_dim_y * d_orig
        # create the array of the input file
        Y_org, X_org = np.mgrid[Input_re_y_min:Input_re_y_max:d_orig, Input_re_x_min:Input_re_x_max:d_orig]
        if Y_org.shape[0] != Input_dim_y:
            Y_org = Y_org[:-1, :]
            X_org = X_org[:-1, :]
            print("warning: correcting the size of input files")
        if Y_org.shape[1] != Input_dim_x:
            Y_org = Y_org[:, :-1]
            X_org = X_org[:, :-1]
        Y_org, X_org = Y_org + d_orig / 2, X_org + d_orig / 2
        # create the array of the fine grid
        Y_fine, X_fine = np.mgrid[F_re_y_min - d_fine:F_re_y_max + d_fine:d_fine,
                         F_re_x_min - d_fine:F_re_x_max + d_fine:d_fine]
        Y_fine, X_fine = Y_fine + d_fine / 2, X_fine + d_fine / 2
        dim_y_fine, dim_x_fine = Y_fine.shape

        # obtain the 2D matrix which maps source plan to imaging plan.
        M = drizzle_matrix_fast(d_drizzle, d_fine, Input_dim_x, Input_dim_y, X_org, Y_org, dim_x_fine, dim_y_fine,
                                X_fine, Y_fine)

        total_noise = np.zeros((dim_y_fine*dim_x_fine, dim_y_fine*dim_x_fine))
        #print(total_noise.shape)
        total_noise = [total_noise.tolist()]  # change to 3D list data structure
        cube = fits.open(directory + argv[i + 2])[1].data  # take the noise map rather than primary data.
        if combine_type == -1 and stacking_N == -1:
            cube_new = grouped_Avg(cube, N=10)
        elif combine_type != -1 and stacking_N == -1:
            if combine_type == 1:
                cube_new = grouped_Avg(cube, N=10)
            elif combine_type == 2:
                cube_new = grouped_Median(cube, N=10)
            else:
                raise ValueError('-1 = default (average); 1 = average; 2 = median')
        elif combine_type == -1 and stacking_N != -1:
            cube_new = grouped_Avg(cube, N=int(stacking_N))
        else:
            if combine_type == 1:
                cube_new = grouped_Avg(cube, N=int(stacking_N))
            elif combine_type == 2:
                cube_new = grouped_Median(cube, N=int(stacking_N))
            else:
                raise ValueError('-1 = default (average); 1 = average; 2 = median')
        for j in range(cube_new.shape[2]):
            print("channel", j+1, "total:", cube_new.shape[2])
            noise = cube_new[:, :, j].ravel()
            M = np.asarray(M)
            new_M = np.asmatrix((noise[None, :]*M)**0.5)
            cov = new_M * new_M.T
            total_noise.append(cov.tolist())
        total_noise = np.asarray(total_noise)
        total_noise = np.swapaxes(total_noise, 0, 1)
        total_noise = np.swapaxes(total_noise, 1, 2)
        end = time.time()
        print("time for drizzling number %d frame" % (i + 1), round(end - start, 2), "seconds")
        final_n_mask_is_zero = final_noise == 0
        final_n_mask_is_nonzero = final_noise != 0
        total_n_mask_is_zero = total_noise[:, :, 1:] == 0
        total_n_mask_is_nonzero = total_noise[:, :, 1:] != 0
        weight1 = final_noise * final_n_mask_is_zero + total_noise[:, :, 1:]
        weight2 = final_noise * final_n_mask_is_nonzero + total_noise[:, :, 1:] * total_n_mask_is_zero
        weight3_1 = final_noise * total_noise[:, :, 1:]/(final_noise ** 2 + total_noise[:, :, 1:] ** 2) ** 0.5
        weight3_1[np.isnan(weight3_1)] = 0
        weight3 = final_n_mask_is_nonzero * total_n_mask_is_nonzero * weight3_1
        final_noise = weight1 + weight2 + weight3  # get rid of the first zeros
    #final_noise[final_noise == 0] = np.inf
    return final_noise


def combine_noise_wcs(argv, d_orig, d_drizzle, d_fine, F_re_y_min, F_re_y_max, F_re_x_min, F_re_x_max):
    final_noise = 0
    directory = argv[1]+"/"
    stacking_N = float(argv[-3])
    combine_type = float(argv[-2])
    Number_of_files = len(argv) - 7
    print(Number_of_files, "frames need to be drizzled")
    for i in range(Number_of_files):
        start = time.time()
        # input file coordinate
        # the dimension of the input file
        Input_dim_x = get_wcs(directory + argv[i + 2])[1]
        Input_dim_y = get_wcs(directory + argv[i + 2])[2]
        # the reference point of the most bottom left pixel of the input file
        Input_re_x_min = get_wcs(directory + argv[i + 2])[3]
        Input_re_y_min = get_wcs(directory + argv[i + 2])[4]
        # the reference point of the most top right pixel of the input file
        Input_re_x_max = Input_re_x_min + Input_dim_x * d_orig
        Input_re_y_max = Input_re_y_min + Input_dim_y * d_orig
        # create the array of the input file
        Y_org, X_org = np.mgrid[Input_re_y_min:Input_re_y_max:d_orig, Input_re_x_min:Input_re_x_max:d_orig]
        if Y_org.shape[0] != Input_dim_y:
            Y_org = Y_org[:-1, :]
            X_org = X_org[:-1, :]
            print("warning: correcting the size of input files")
        if Y_org.shape[1] != Input_dim_x:
            Y_org = Y_org[:, :-1]
            X_org = X_org[:, :-1]
        Y_org, X_org = Y_org + d_orig / 2, X_org + d_orig / 2
        # create the array of the fine grid
        Y_fine, X_fine = np.mgrid[F_re_y_min - d_fine:F_re_y_max + d_fine:d_fine,
                         F_re_x_min - d_fine:F_re_x_max + d_fine:d_fine]
        Y_fine, X_fine = Y_fine + d_fine / 2, X_fine + d_fine / 2
        dim_y_fine, dim_x_fine = Y_fine.shape

        # obtain the 2D matrix which maps source plan to imaging plan.
        M = drizzle_matrix_fast(d_drizzle, d_fine, Input_dim_x, Input_dim_y, X_org, Y_org, dim_x_fine, dim_y_fine,
                                X_fine, Y_fine)

        total_noise = np.zeros((dim_y_fine*dim_x_fine, dim_y_fine*dim_x_fine))
        total_noise = [total_noise.tolist()]  # change to 3D list data structure
        cube = fits.open(directory + argv[i + 2])[1].data
        if combine_type == -1 and stacking_N == -1:
            cube_new = grouped_Avg(cube, N=10)
        elif combine_type != -1 and stacking_N == -1:
            if combine_type == 1:
                cube_new = grouped_Avg(cube, N=10)
            elif combine_type == 2:
                cube_new = grouped_Median(cube, N=10)
            else:
                raise ValueError('-1 = default (average); 1 = average; 2 = median')
        elif combine_type == -1 and stacking_N != -1:
            cube_new = grouped_Avg(cube, N=int(stacking_N))
        else:
            if combine_type == 1:
                cube_new = grouped_Avg(cube, N=int(stacking_N))
            elif combine_type == 2:
                cube_new = grouped_Median(cube, N=int(stacking_N))
            else:
                raise ValueError('-1 = default (average); 1 = average; 2 = median')
        for j in range(cube_new.shape[2]):
            print("channel", j+1, "total:", cube_new.shape[2])
            noise = cube_new[:, :, j].ravel()
            M = np.asarray(M)
            new_M = np.asmatrix((noise[None, :]*M)**0.5)
            cov = new_M * new_M.T
            total_noise.append(cov.tolist())
        total_noise = np.asarray(total_noise)
        total_noise = np.swapaxes(total_noise, 0, 1)
        total_noise = np.swapaxes(total_noise, 1, 2)
        end = time.time()
        print("time for drizzling number %d frame" % (i + 1), round(end - start, 2), "seconds")
        final_n_mask_is_zero = final_noise == 0
        final_n_mask_is_nonzero = final_noise != 0
        total_n_mask_is_zero = total_noise[:, :, 1:] == 0
        total_n_mask_is_nonzero = total_noise[:, :, 1:] != 0
        weight1 = final_noise * final_n_mask_is_zero + total_noise[:, :, 1:]
        weight2 = final_noise * final_n_mask_is_nonzero + total_noise[:, :, 1:] * total_n_mask_is_zero
        weight3_1 = final_noise * total_noise[:, :, 1:]/(final_noise ** 2 + total_noise[:, :, 1:] ** 2) ** 0.5
        weight3_1[np.isnan(weight3_1)] = 0
        weight3 = final_n_mask_is_nonzero * total_n_mask_is_nonzero * weight3_1
        final_noise = weight1 + weight2 + weight3  # get rid of the first zeros
    #final_noise[final_noise == 0] = np.inf
    return final_noise


def header(data, d_fine, F_re_y_min, F_re_x_min, argv):
    directory = argv[1] + "/"
    stacking_N = float(argv[-3])
    if stacking_N == -1:
        stacking_N = 10
    #print((stacking_N))
    hdu_org = fits.open(directory+argv[2])
    wave_length = hdu_org[0].header["CRVAL1"]
    wave_length_gap = hdu_org[0].header["CDELT1"]
    PC22 = hdu_org[0].header["PC2_2"]
    PC33 = hdu_org[0].header["PC3_3"]
    degree = round(np.arccos(PC22) / np.pi * 180, 0)
    Dec = hdu_org[0].header["CRVAL2"]
    RA = hdu_org[0].header["CRVAL3"]
    #print(wave_length_gap)
    hdu = fits.PrimaryHDU(data)
    hdul = fits.HDUList([hdu])
    step_wl = stacking_N * wave_length_gap
    #print(step_wl)
    hdul[0].header.set('FLIP')
    hdul[0].header["FLIP"] = ('TRUE', 'OSIRIS move to Keck I necessitates a flip')
    hdul[0].header.set('CTYPE1')
    hdul[0].header["CTYPE1"] = ('WAVE', 'Vacuum wavelength.')
    hdul[0].header.set('CTYPE2')
    hdul[0].header["CTYPE2"] = ('DEC--TAN', 'Declination')
    hdul[0].header.set('CTYPE3')
    hdul[0].header["CTYPE3"] = ('RA---TAN', 'Right Ascension.')
    hdul[0].header.set('CUNIT1')
    hdul[0].header["CUNIT1"] = ('nm', 'Vacuum wavelength unit is nanometers')
    hdul[0].header.set('CUNIT2')
    hdul[0].header["CUNIT2"] = ('deg', 'Declination unit is degrees, always')
    hdul[0].header.set('CUNIT3')
    hdul[0].header["CUNIT3"] = ('deg', 'R.A. unit is degrees, always')
    hdul[0].header.set('CRVAL1')
    hdul[0].header["CRVAL1"] = (wave_length, '[nm] Wavelength at reference pixel')
    hdul[0].header.set('CRVAL2')
    hdul[0].header["CRVAL2"] = (Dec, '[deg] Declination at reference pxiel')
    hdul[0].header.set('CRVAL3')
    hdul[0].header["CRVAL3"] = (RA, '[deg] R.A. at reference pixel')
    hdul[0].header.set('CRPIX1')
    hdul[0].header["CRPIX1"] = (1, 'Reference pixel location')
    hdul[0].header.set('CRPIX2')
    hdul[0].header["CRPIX2"] = (0, 'Reference pixel location')
    hdul[0].header.set('CRPIX3')
    hdul[0].header["CRPIX3"] = (0, 'Reference pixel location')
    hdul[0].header.set('CDELT1')
    hdul[0].header["CDELT1"] = (step_wl, 'Wavelength scale is %s nm / channel' % step_wl)
    hdul[0].header.set('CDELT2')
    hdul[0].header["CDELT2"] = (d_fine/3600, 'Pixel scale is %s arcsec / pixel' % d_fine)
    hdul[0].header.set('CDELT3')
    hdul[0].header["CDELT3"] = (d_fine/3600, 'Pixel scale is %s arcsec / pixel' % d_fine)
    hdul[0].header.set('PC1_1')
    hdul[0].header["PC1_1"] = (1, 'Spectral axis is unrotated')
    hdul[0].header.set('PC2_2')
    hdul[0].header["PC2_2"] = (PC22, 'RA, Dec axes rotated by %s degr.' % degree)
    hdul[0].header.set('PC2_3')
    hdul[0].header["PC2_3"] = (1, 'RA, Dec axes rotated by %s degr.' % degree)
    hdul[0].header.set('PC3_2')
    hdul[0].header["PC3_2"] = (1, 'RA, Dec axes rotated by %s degr.' % degree)
    hdul[0].header.set('PC3_3')
    hdul[0].header["PC3_3"] = (PC33, 'RA, Dec axes rotated by %s degr.' % degree)
    return hdul

def is_not_number(s):
    try:
        float(s)
        return False
    except ValueError:
        return True


def is_number(s):
    try:
        float(s)
        return True
    except ValueError:
        return False


